<?php

namespace Tests\Feature\Security\Auth;


use PHPUnit\Framework\Attributes\Group;
use App\Services\PlatformSettingsService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;
use Tests\TestCase;

#[Group('security')]
class RegisterSecurityTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
        Cache::flush();
        RateLimiter::clear('register');

        /** @var PlatformSettingsService $settings */
        $settings = app(PlatformSettingsService::class);
        $settings->set('student_self_registration_enabled', true, 'registration');
        $settings->set('email_verification_required', false, 'registration');
        $settings->set('terms_required', false, 'registration');
        $settings->set('phone_required', false, 'registration');
        $settings->set('device_id_required', false, 'students');
        $settings->set('device_binding_enabled', false, 'students');
    }

    public function test_normal_registration_succeeds(): void
    {
        $email = 'register-'.Str::uuid().'@rshd.test';

        $this->postJson('/api/v1/register', $this->validPayload($email))
            ->assertCreated()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('users', [
            'email' => $email,
            'role' => 'student',
        ]);
    }

    public function test_repeated_registration_attempts_are_throttled(): void
    {
        for ($i = 0; $i < 10; $i++) {
            $this->postJson('/api/v1/register', $this->validPayload('throttle-'.$i.'@rshd.test'))
                ->assertCreated();
        }

        $this->postJson('/api/v1/register', $this->validPayload('throttle-overflow@rshd.test'))
            ->assertStatus(429);
    }

    public function test_invalid_payload_is_rejected(): void
    {
        $this->postJson('/api/v1/register', [
            'email' => 'not-an-email',
            'password' => 'short',
        ])->assertStatus(422);
    }

    public function test_duplicate_email_is_handled_safely(): void
    {
        $email = 'duplicate-'.Str::uuid().'@rshd.test';

        $this->postJson('/api/v1/register', $this->validPayload($email))
            ->assertCreated();

        $this->postJson('/api/v1/register', $this->validPayload($email))
            ->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    public function test_oversized_input_is_rejected(): void
    {
        $this->postJson('/api/v1/register', $this->validPayload('oversized@rshd.test', [
            'name' => str_repeat('أ', 300),
        ]))->assertStatus(422)
            ->assertJsonValidationErrors(['name']);
    }

    /**
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    protected function validPayload(string $email, array $overrides = []): array
    {
        return array_merge([
            'name' => 'طالب تجريبي',
            'email' => $email,
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ], $overrides);
    }
}
