<?php

namespace Tests\Feature\Push;

use App\Jobs\SendPushNotificationJob;
use App\Models\AppNotification;
use App\Models\PushDeviceToken;
use App\Models\User;
use App\Services\PlatformNotificationService;
use App\Services\PlatformSettingsService;
use App\Services\Push\FcmClient;
use App\Services\Push\PushMessageBuilder;
use App\Services\Push\PushNotificationService;
use App\Services\StudentSessionService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Queue;
use Tests\Feature\Push\Concerns\FakesFirebase;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

class PushDeliveryTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use FakesFirebase;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
        app(PlatformSettingsService::class)->set('push_notifications_enabled', true, 'notifications');
        app(PlatformSettingsService::class)->set('email_notifications_enabled', false, 'notifications');
    }

    private function studentWithDevice(string $token = 'fcm-device-token-0000000000000000000000:A', array $preferences = []): User
    {
        $student = $this->createStudent(['preferences' => $preferences ?: null]);
        $session = app(StudentSessionService::class)->issue($student, 'phone-a');
        app(PushNotificationService::class)->register($student, $session->accessToken, $token, 'android', 'phone-a', '1.0.0');

        return $student;
    }

    private function notifyGrade(User $student): void
    {
        app(PlatformNotificationService::class)->notifyUser(
            user: $student,
            title: 'درجة جديدة',
            body: 'تم نشر درجتك.',
            type: 'grade_published',
            settingKey: 'notify_student_grade_published',
            data: ['grade_id' => 7, 'subject_id' => 3],
        );
    }

    public function test_a_notification_is_saved_in_app_and_queued_for_push(): void
    {
        Queue::fake();
        $student = $this->studentWithDevice();

        $this->notifyGrade($student);

        $notification = AppNotification::query()->sole();
        Queue::assertPushed(SendPushNotificationJob::class, fn (SendPushNotificationJob $job): bool => $job->notificationId === $notification->id
            && $job->userId === $student->id
            && $job->data === ['grade_id' => 7, 'subject_id' => 3]);
    }

    public function test_push_respects_the_platform_switch_and_the_students_preference(): void
    {
        Queue::fake();

        $optedOut = $this->studentWithDevice(preferences: ['notify_grades' => false]);
        $this->notifyGrade($optedOut);
        Queue::assertNothingPushed();
        $this->assertSame(1, $optedOut->notifications()->count(), 'the in-app copy is still kept');

        app(PlatformSettingsService::class)->set('push_notifications_enabled', false, 'notifications');
        $student = $this->studentWithDevice('fcm-device-token-1111111111111111111111:B');
        $this->notifyGrade($student);
        Queue::assertNothingPushed();
        $this->assertSame(1, $student->notifications()->count());
    }

    public function test_nothing_is_queued_for_a_student_without_a_device(): void
    {
        Queue::fake();
        $student = $this->createStudent();

        $this->notifyGrade($student);

        Queue::assertNothingPushed();
        $this->assertSame(1, $student->notifications()->count());
    }

    public function test_the_job_sends_the_tap_payload_once(): void
    {
        $this->configureFakeFirebase();
        $this->fakeFirebaseHttp();
        $student = $this->studentWithDevice();

        $this->notifyGrade($student); // sync queue in tests: sends now
        $notification = AppNotification::query()->sole();

        Http::assertSent(function (Request $request) use ($notification, $student): bool {
            if (! str_contains($request->url(), 'fcm.googleapis.com/v1/projects/rshd-test/messages:send')) {
                return false;
            }
            $message = $request->data()['message'];

            return $request->hasHeader('Authorization', 'Bearer test-access')
                && $message['token'] === 'fcm-device-token-0000000000000000000000:A'
                && $message['notification']['title'] === 'درجة جديدة'
                && $message['data']['notification_id'] === (string) $notification->id
                && $message['data']['user_id'] === (string) $student->id
                && $message['data']['type'] === 'grade_published'
                && json_decode($message['data']['rshd_data'], true) === ['grade_id' => 7, 'subject_id' => 3]
                && $message['android']['notification']['channel_id'] === 'rshd_general'
                && $message['apns']['headers']['apns-collapse-id'] === 'rshd-n-'.$notification->id;
        });
        $this->assertNotNull($notification->fresh()->push_sent_at);

        // A duplicated job finds the notification already pushed.
        (new SendPushNotificationJob($student->id, 'درجة جديدة', 'تم نشر درجتك.', 'grade_published', [], $notification->id))
            ->handle(app(FcmClient::class), app(PushMessageBuilder::class));

        Http::assertSentCount(2); // one OAuth exchange + one send
    }

    public function test_a_dead_token_is_forgotten(): void
    {
        $this->configureFakeFirebase();
        $this->fakeFirebaseHttp([
            [['error' => ['status' => 'NOT_FOUND', 'details' => [['errorCode' => 'UNREGISTERED']]]], 404],
        ]);
        $student = $this->studentWithDevice();

        $this->notifyGrade($student);

        $this->assertSame(0, PushDeviceToken::query()->count());
    }

    public function test_a_transient_failure_releases_the_claim_for_a_retry(): void
    {
        $this->configureFakeFirebase();
        $this->fakeFirebaseHttp([
            [['error' => ['status' => 'UNAVAILABLE']], 503],
        ]);
        $student = $this->studentWithDevice();
        $notification = AppNotification::query()->create([
            'user_id' => $student->id,
            'title' => 'اختبار',
            'body' => 'نص',
            'type' => 'custom',
            'is_read' => false,
        ]);

        $job = new SendPushNotificationJob($student->id, 'اختبار', 'نص', 'custom', [], $notification->id);
        $job->withFakeQueueInteractions();
        $job->handle(app(FcmClient::class), app(PushMessageBuilder::class));

        $job->assertReleased();
        $this->assertNull($notification->fresh()->push_sent_at);
        $this->assertSame(1, PushDeviceToken::query()->count(), 'a transient failure keeps the token');
    }

    public function test_without_server_credentials_nothing_is_sent_and_nothing_breaks(): void
    {
        config(['services.firebase.credentials' => '/nonexistent/key.json', 'services.firebase.credentials_json' => null]);
        Http::fake();
        $student = $this->studentWithDevice();

        $this->notifyGrade($student);

        Http::assertNothingSent();
        $this->assertSame(1, $student->notifications()->count());
        $this->assertNull(AppNotification::query()->sole()->push_sent_at);
    }
}
