<?php

namespace Tests\Feature\Push;

use App\Models\PushDeviceToken;
use App\Services\DeviceService;
use App\Services\StudentSessionService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

/**
 * An FCM token belongs to the session it was registered with: it moves with
 * the install between accounts and disappears with the session.
 */
class PushTokenRegistrationTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    private const TOKEN_A = 'fcm-token-aaaaaaaaaaaaaaaaaaaaaaaaaaaa:APA91b-1';

    private const TOKEN_B = 'fcm-token-bbbbbbbbbbbbbbbbbbbbbbbbbbbb:APA91b-2';

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    private function register(string $plainToken, string $fcmToken, string $device = 'phone-a', string $platform = 'ios')
    {
        // Each call is a fresh request; don't reuse the user resolved earlier.
        $this->app['auth']->forgetGuards();

        return $this->withToken($plainToken)->postJson(
            '/api/v1/push-tokens',
            ['token' => $fcmToken, 'platform' => $platform, 'app_version' => '1.0.0'],
            ['X-Device-Id' => $device],
        );
    }

    public function test_a_token_is_bound_to_the_session_and_its_device(): void
    {
        $student = $this->createStudent();
        $session = app(StudentSessionService::class)->issue($student, 'phone-a');

        $this->register($session->plainTextToken, self::TOKEN_A)->assertOk();

        $row = PushDeviceToken::query()->sole();
        $this->assertSame($student->id, $row->user_id);
        $this->assertSame($session->accessToken->id, $row->personal_access_token_id);
        $this->assertSame('phone-a', $row->device_id);
        $this->assertSame('ios', $row->platform);
        $this->assertSame(self::TOKEN_A, $row->token);

        // Stored encrypted, looked up by hash.
        $raw = DB::table('push_device_tokens')->value('token');
        $this->assertNotSame(self::TOKEN_A, $raw);
        $this->assertSame(hash('sha256', self::TOKEN_A), $row->token_hash);
    }

    public function test_the_same_install_signing_into_another_account_moves_the_token(): void
    {
        $first = $this->createStudent();
        $second = $this->createStudent();

        $this->register(app(StudentSessionService::class)->issue($first, 'phone-a')->plainTextToken, self::TOKEN_A)->assertOk();
        $this->register(app(StudentSessionService::class)->issue($second, 'phone-a')->plainTextToken, self::TOKEN_A)->assertOk();

        $this->assertSame([$second->id], PushDeviceToken::query()->pluck('user_id')->all());
        $this->assertSame(0, $first->pushDeviceTokens()->count());
    }

    public function test_a_refreshed_token_replaces_the_old_one_for_that_session(): void
    {
        $student = $this->createStudent();
        $plain = app(StudentSessionService::class)->issue($student, 'phone-a')->plainTextToken;

        $this->register($plain, self::TOKEN_A)->assertOk();
        $this->register($plain, self::TOKEN_B)->assertOk();

        $this->assertSame([self::TOKEN_B], PushDeviceToken::query()->get()->pluck('token')->all());
    }

    public function test_signing_out_removes_the_token(): void
    {
        $student = $this->createStudent();
        $plain = app(StudentSessionService::class)->issue($student, 'phone-a')->plainTextToken;
        $this->register($plain, self::TOKEN_A)->assertOk();

        $this->app['auth']->forgetGuards();
        $this->withToken($plain)
            ->postJson('/api/v1/logout', [], ['X-Device-Id' => 'phone-a'])
            ->assertOk();

        $this->assertSame(0, PushDeviceToken::query()->count());
    }

    public function test_ending_every_session_or_resetting_devices_removes_the_tokens(): void
    {
        $student = $this->createStudent();
        $sessions = app(StudentSessionService::class);

        $this->register($sessions->issue($student, 'phone-a')->plainTextToken, self::TOKEN_A)->assertOk();
        $this->register($sessions->issue($student, 'tablet-b')->plainTextToken, self::TOKEN_B, 'tablet-b')->assertOk();
        $this->assertSame(2, $student->pushDeviceTokens()->count());

        app(DeviceService::class)->resetStudentDevices($student);

        $this->assertSame(0, $student->pushDeviceTokens()->count());
    }

    public function test_unregistering_only_touches_the_callers_own_token(): void
    {
        $owner = $this->createStudent();
        $other = $this->createStudent();
        $this->register(app(StudentSessionService::class)->issue($owner, 'phone-a')->plainTextToken, self::TOKEN_A)->assertOk();

        $this->app['auth']->forgetGuards();
        $this->withToken(app(StudentSessionService::class)->issue($other, 'phone-z')->plainTextToken)
            ->deleteJson('/api/v1/push-tokens', ['token' => self::TOKEN_A], ['X-Device-Id' => 'phone-z'])
            ->assertOk();

        $this->assertSame(1, $owner->pushDeviceTokens()->count());
    }

    public function test_invalid_registrations_are_rejected(): void
    {
        $student = $this->createStudent();
        $plain = app(StudentSessionService::class)->issue($student, 'phone-a')->plainTextToken;

        $this->register($plain, self::TOKEN_A, platform: 'windows')->assertUnprocessable();
        $this->register($plain, 'short')->assertUnprocessable();
        $this->register($plain, 'bad token with spaces and <html> ......')->assertUnprocessable();

        $this->app['auth']->forgetGuards();
        $this->withoutToken()
            ->postJson('/api/v1/push-tokens', ['token' => self::TOKEN_A, 'platform' => 'ios'])
            ->assertUnauthorized();
        $this->assertSame(0, PushDeviceToken::query()->count());
    }
}
