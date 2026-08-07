<?php

namespace Tests\Feature;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\PaymentStatus;
use App\Enums\SubjectCategory;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Enums\VideoStatus;
use App\Models\Lesson;
use App\Models\Subject;
use App\Models\SubjectStudent;
use App\Models\User;
use App\Models\Video;
use App\Services\Video\LocalVideoProvider;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class VideoPlaybackTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
        Storage::fake('public');
        Storage::fake('lesson_videos');

        Config::set('video.signed_playback', true);
        Config::set('video.playback_ttl', 600);
        Config::set('video.signing_key', 'test-signing-key');
        Config::set('video.local.disk', 'lesson_videos');
    }

    public function test_unauthenticated_user_cannot_access_video(): void
    {
        $video = $this->createVideoWithEnrollment();

        $this->getJson('/api/v1/videos/'.$video->id)
            ->assertUnauthorized();
    }

    public function test_enrolled_student_receives_signed_playback_url(): void
    {
        [$student, $video] = $this->createEnrolledStudentScenario();

        Sanctum::actingAs($student);

        $response = $this->getJson('/api/v1/videos/'.$video->id)
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'playback' => ['url', 'expires_at'],
                ],
            ]);

        $url = (string) $response->json('data.playback.url');
        $this->assertStringContainsString('/api/v1/videos/'.$video->id.'/stream', $url);
        $this->assertStringContainsString('token=', $url);
        $this->assertStringContainsString('expires=', $url);
    }

    public function test_local_video_is_not_stored_on_public_disk(): void
    {
        [$student, $video] = $this->createEnrolledStudentScenario();

        $this->assertTrue(Storage::disk('lesson_videos')->exists($video->video_path));
        $this->assertFalse(Storage::disk('public')->exists($video->video_path));
        $this->assertNull($video->fresh()->resolvedExternalVideoUrl());

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/videos/'.$video->id)->assertOk();
    }

    public function test_unenrolled_student_is_forbidden(): void
    {
        $video = $this->createVideoWithEnrollment();
        $other = $this->createStudent(['email' => 'other@rshdacademy.com']);

        Sanctum::actingAs($other);

        $this->getJson('/api/v1/videos/'.$video->id)
            ->assertForbidden();
    }

    public function test_missing_video_returns_not_found(): void
    {
        $student = $this->createStudent();

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/videos/999999')
            ->assertNotFound();
    }

    public function test_student_cannot_access_video_from_other_subject(): void
    {
        [$student] = $this->createEnrolledStudentScenario();
        $otherSubject = $this->createSubject();
        $otherLesson = $this->createLesson($otherSubject);
        $otherVideo = $this->createVideo($otherLesson);

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/videos/'.$otherVideo->id)
            ->assertForbidden();
    }

    public function test_response_does_not_expose_original_video_url_or_storage_fields(): void
    {
        [$student, $video] = $this->createEnrolledStudentScenario();

        Sanctum::actingAs($student);

        $response = $this->getJson('/api/v1/videos/'.$video->id)->assertOk();
        $payload = json_encode($response->json(), JSON_THROW_ON_ERROR);

        $this->assertStringNotContainsString('video_url', $payload);
        $this->assertStringNotContainsString('video_path', $payload);
        $this->assertStringNotContainsString('external_video_id', $payload);
        $this->assertStringNotContainsString('test-signing-key', $payload);
        $this->assertStringNotContainsString('BUNNY_STREAM', $payload);
    }

    public function test_playback_url_contains_expiry_within_configured_ttl(): void
    {
        [$student, $video] = $this->createEnrolledStudentScenario();

        Sanctum::actingAs($student);

        $response = $this->getJson('/api/v1/videos/'.$video->id)->assertOk();
        $expiresAt = strtotime((string) $response->json('data.playback.expires_at'));
        $now = now()->getTimestamp();

        $this->assertGreaterThan($now, $expiresAt);
        $this->assertLessThanOrEqual($now + 600, $expiresAt);
    }

    public function test_refresh_playback_rechecks_authorization(): void
    {
        [$student, $video] = $this->createEnrolledStudentScenario();
        $other = $this->createStudent(['email' => 'blocked@rshdacademy.com']);

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/videos/'.$video->id.'/playback')
            ->assertOk()
            ->assertJsonStructure(['data' => ['playback' => ['url', 'expires_at']]]);

        Sanctum::actingAs($other);

        $this->getJson('/api/v1/videos/'.$video->id.'/playback')
            ->assertForbidden();
    }

    public function test_progress_update_works_for_authorized_student(): void
    {
        [$student, $video] = $this->createEnrolledStudentScenario();

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/videos/'.$video->id.'/progress', [
            'watched_seconds' => 30,
            'current_position' => 30,
            'completion_percentage' => 25,
        ])->assertOk()
            ->assertJsonPath('data.current_position', 30);
    }

    public function test_progress_update_is_forbidden_for_unauthorized_student(): void
    {
        $video = $this->createVideoWithEnrollment();
        $other = $this->createStudent(['email' => 'noprog@rshdacademy.com']);

        Sanctum::actingAs($other);

        $this->postJson('/api/v1/videos/'.$video->id.'/progress', [
            'watched_seconds' => 30,
            'current_position' => 30,
        ])->assertForbidden();
    }

    public function test_changing_video_id_manually_does_not_bypass_protection(): void
    {
        [$student] = $this->createEnrolledStudentScenario();
        $lockedVideo = $this->createVideoWithEnrollment();

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/videos/'.$lockedVideo->id)
            ->assertForbidden();
    }

    public function test_progress_rejects_out_of_range_position(): void
    {
        [$student, $video] = $this->createEnrolledStudentScenario();

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/videos/'.$video->id.'/progress', [
            'watched_seconds' => 9999,
            'current_position' => 9999,
        ])->assertStatus(422);
    }

    public function test_local_stream_endpoint_rejects_missing_signature(): void
    {
        [$student, $video] = $this->createEnrolledStudentScenario();

        $this->get('/api/v1/videos/'.$video->id.'/stream')
            ->assertForbidden();
    }

    public function test_local_stream_endpoint_rejects_invalid_token(): void
    {
        [$student, $video] = $this->createEnrolledStudentScenario();

        $this->get('/api/v1/videos/'.$video->id.'/stream?uid='.$student->id.'&expires='.(now()->addMinutes(5)->getTimestamp()).'&token=invalid')
            ->assertForbidden();
    }

    public function test_local_stream_endpoint_rejects_expired_token(): void
    {
        [$student, $video] = $this->createEnrolledStudentScenario();
        $provider = app(LocalVideoProvider::class);
        $expires = now()->subMinute();
        $token = $provider->buildStreamToken($video->id, $student->id, $expires);

        $this->get('/api/v1/videos/'.$video->id.'/stream?uid='.$student->id.'&expires='.$expires->getTimestamp().'&token='.$token)
            ->assertForbidden();
    }

    public function test_local_stream_endpoint_rejects_token_for_different_user(): void
    {
        [$student, $video] = $this->createEnrolledStudentScenario();
        $other = $this->createStudent(['email' => 'tokenother@rshdacademy.com']);
        $provider = app(LocalVideoProvider::class);
        $expires = now()->addMinutes(5);
        $token = $provider->buildStreamToken($video->id, $other->id, $expires);

        $this->get('/api/v1/videos/'.$video->id.'/stream?uid='.$other->id.'&expires='.$expires->getTimestamp().'&token='.$token)
            ->assertForbidden();
    }

    public function test_local_stream_endpoint_serves_authorized_token(): void
    {
        [$student, $video] = $this->createEnrolledStudentScenario();

        Sanctum::actingAs($student);

        $playbackUrl = (string) $this->getJson('/api/v1/videos/'.$video->id.'/playback')
            ->assertOk()
            ->json('data.playback.url');

        $path = parse_url($playbackUrl, PHP_URL_PATH);
        $query = parse_url($playbackUrl, PHP_URL_QUERY);

        $this->get($path.'?'.$query)
            ->assertOk();
    }

    public function test_local_stream_supports_range_requests(): void
    {
        [$student, $video] = $this->createEnrolledStudentScenario(content: str_repeat('A', 1000));
        $provider = app(LocalVideoProvider::class);
        $expires = now()->addMinutes(5);
        $token = $provider->buildStreamToken($video->id, $student->id, $expires);

        $response = $this->call(
            'GET',
            '/api/v1/videos/'.$video->id.'/stream',
            [
                'uid' => $student->id,
                'expires' => $expires->getTimestamp(),
                'token' => $token,
            ],
            [],
            [],
            ['HTTP_RANGE' => 'bytes=0-99'],
        );

        $response->assertStatus(206);
        $response->assertHeader('Accept-Ranges', 'bytes');
        $response->assertHeader('Content-Range', 'bytes 0-99/1000');
        $this->assertSame(100, strlen($response->streamedContent()));
    }

    public function test_active_enrollment_without_expires_at_allows_playback(): void
    {
        [$student, $video] = $this->createEnrolledStudentScenario(expiresAt: null);

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/videos/'.$video->id)->assertOk();
    }

    public function test_future_expires_at_allows_playback(): void
    {
        [$student, $video] = $this->createEnrolledStudentScenario(
            expiresAt: now()->addDays(7),
        );

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/videos/'.$video->id)->assertOk();
    }

    public function test_expired_enrollment_denies_playback_and_progress(): void
    {
        [$student, $video] = $this->createEnrolledStudentScenario(
            expiresAt: now()->subMinute(),
        );

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/videos/'.$video->id)->assertForbidden();
        $this->getJson('/api/v1/videos/'.$video->id.'/playback')->assertForbidden();
        $this->postJson('/api/v1/videos/'.$video->id.'/progress', [
            'watched_seconds' => 10,
            'current_position' => 10,
        ])->assertForbidden();
    }

    public function test_playback_expiry_is_capped_by_enrollment_expiry(): void
    {
        Carbon::setTestNow(now());

        [$student, $video] = $this->createEnrolledStudentScenario(
            expiresAt: now()->addSeconds(90),
        );

        Sanctum::actingAs($student);

        $response = $this->getJson('/api/v1/videos/'.$video->id)->assertOk();
        $expiresAt = Carbon::parse((string) $response->json('data.playback.expires_at'));

        $this->assertTrue($expiresAt->lte(now()->addSeconds(90)));
        $this->assertTrue($expiresAt->gt(now()->addSeconds(80)));

        Carbon::setTestNow();
    }

    public function test_refresh_after_enrollment_expires_is_forbidden(): void
    {
        [$student, $video] = $this->createEnrolledStudentScenario(
            expiresAt: now()->addSeconds(30),
        );

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/videos/'.$video->id.'/playback')->assertOk();

        Carbon::setTestNow(now()->addMinute());

        $this->getJson('/api/v1/videos/'.$video->id.'/playback')->assertForbidden();

        Carbon::setTestNow();
    }

    public function test_migrate_to_private_command_moves_public_files_safely(): void
    {
        Storage::fake('public');
        Storage::fake('lesson_videos');

        $subject = $this->createSubject();
        $lesson = $this->createLesson($subject);
        $path = 'lesson-videos/migrate-me.mp4';
        $content = 'video-binary-content';

        Storage::disk('public')->put($path, $content);

        $video = Video::query()->create([
            'lesson_id' => $lesson->id,
            'title' => 'Migrate me',
            'storage_provider' => 'local',
            'video_url' => '',
            'video_path' => $path,
            'duration_seconds' => 60,
            'status' => VideoStatus::Ready,
        ]);

        $this->artisan('videos:migrate-to-private')
            ->assertSuccessful();

        $this->assertTrue(Storage::disk('lesson_videos')->exists($path));
        $this->assertTrue(Storage::disk('public')->exists($path));
        $this->assertSame(
            Storage::disk('public')->checksum($path),
            Storage::disk('lesson_videos')->checksum($path),
        );

        $this->artisan('videos:migrate-to-private', ['--remove-source' => true])
            ->assertSuccessful();

        $this->assertTrue(Storage::disk('lesson_videos')->exists($path));
        $this->assertFalse(Storage::disk('public')->exists($path));

        $this->artisan('videos:migrate-to-private')
            ->assertSuccessful();

        $this->assertTrue(Storage::disk('lesson_videos')->exists($path));
        $this->assertSame($path, $video->fresh()->video_path);
    }

    /**
     * @return array{0: User, 1: Video}
     */
    protected function createEnrolledStudentScenario(
        ?Carbon $expiresAt = null,
        string $content = 'fake-video-bytes',
    ): array {
        $student = $this->createStudent();
        $video = $this->createVideoWithEnrollment($student, $expiresAt, $content);

        return [$student, $video];
    }

    protected function createVideoWithEnrollment(
        ?User $student = null,
        ?Carbon $expiresAt = null,
        string $content = 'fake-video-bytes',
    ): Video {
        $student ??= $this->createStudent(['email' => 'enrolled@rshdacademy.com']);
        $subject = $this->createSubject();
        $lesson = $this->createLesson($subject);

        SubjectStudent::query()->create([
            'subject_id' => $subject->id,
            'student_id' => $student->id,
            'payment_status' => PaymentStatus::Paid,
            'access_status' => AccessStatus::Active,
            'activated_at' => now(),
            'expires_at' => $expiresAt,
        ]);

        return $this->createVideo($lesson, $content);
    }

    protected function createSubject(?User $instructor = null): Subject
    {
        $instructor ??= User::factory()->create([
            'role' => UserRole::Instructor,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
        ]);

        return Subject::query()->create([
            'instructor_id' => $instructor->id,
            'title' => 'مادة تجريبية',
            'description' => 'وصف',
            'category' => SubjectCategory::General->value,
            'status' => ContentStatus::Active,
            'price' => 10,
        ]);
    }

    protected function createLesson(Subject $subject): Lesson
    {
        return Lesson::query()->create([
            'subject_id' => $subject->id,
            'title' => 'درس تجريبي',
            'description' => 'وصف',
            'status' => ContentStatus::Active,
        ]);
    }

    protected function createVideo(Lesson $lesson, string $content = 'fake-video-bytes'): Video
    {
        Storage::disk('lesson_videos')->put('lesson-videos/test-video.mp4', $content);

        return Video::query()->create([
            'lesson_id' => $lesson->id,
            'title' => 'فيديو تجريبي',
            'storage_provider' => 'local',
            'video_url' => '',
            'video_path' => 'lesson-videos/test-video.mp4',
            'duration_seconds' => 120,
            'status' => VideoStatus::Ready,
            'is_free' => false,
        ]);
    }

    /**
     * @param  array<string, mixed>  $overrides
     */
    protected function createStudent(array $overrides = []): User
    {
        $student = User::factory()->create(array_merge([
            'role' => UserRole::Student,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
        ], $overrides));

        $student->assignRole('student');

        return $student;
    }
}
