<?php

namespace Tests\Feature\Security\Auth;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Mail\StudentEmailVerificationCodeMail;
use App\Models\StudentEmailVerificationCode;
use App\Models\User;
use App\Services\PlatformSettingsService;
use App\Services\StudentEmailVerificationService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

/**
 * @group security
 */
class EmailVerificationSecurityTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
        Cache::flush();
        Mail::fake();

        $settings = app(PlatformSettingsService::class);
        $settings->set('email_verification_required', true, 'registration');
        $settings->set('otp_email_enabled', true, 'email');
        $settings->set('device_id_required', false, 'students');
        $settings->set('device_binding_enabled', false, 'students');
    }

    public function test_valid_verification_code_marks_user_verified_and_returns_token(): void
    {
        $user = $this->createUnverifiedStudent('verify-ok@rshd.test');
        $code = $this->sendAndCaptureCode($user);

        $this->postJson('/api/v1/email/verify', [
            'email' => $user->email,
            'code' => $code,
            'device_id' => 'verify-device',
        ])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['token', 'user']]);

        $this->assertNotNull($user->fresh()->email_verified_at);
    }

    public function test_invalid_verification_code_is_rejected(): void
    {
        $user = $this->createUnverifiedStudent('verify-bad@rshd.test');
        $this->sendAndCaptureCode($user);

        $this->postJson('/api/v1/email/verify', [
            'email' => $user->email,
            'code' => '000000',
        ])->assertStatus(422);

        $this->assertNull($user->fresh()->email_verified_at);
    }

    public function test_expired_verification_code_is_rejected(): void
    {
        $user = $this->createUnverifiedStudent('verify-expired@rshd.test');
        $code = $this->sendAndCaptureCode($user);

        StudentEmailVerificationCode::query()
            ->where('user_id', $user->id)
            ->update(['expires_at' => now()->subMinute()]);

        $this->postJson('/api/v1/email/verify', [
            'email' => $user->email,
            'code' => $code,
        ])->assertStatus(422);
    }

    public function test_verification_code_record_is_marked_used_after_success(): void
    {
        $user = $this->createUnverifiedStudent('verify-replay@rshd.test');
        $code = $this->sendAndCaptureCode($user);

        $this->postJson('/api/v1/email/verify', [
            'email' => $user->email,
            'code' => $code,
            'device_id' => 'verify-replay-device',
        ])->assertOk();

        $record = StudentEmailVerificationCode::query()
            ->where('user_id', $user->id)
            ->latest('id')
            ->first();

        $this->assertNotNull($record?->used_at);
        $this->assertNotNull($user->fresh()->email_verified_at);
    }

    public function test_user_a_code_cannot_verify_user_b_account(): void
    {
        $userA = $this->createUnverifiedStudent('verify-a@rshd.test');
        $userB = $this->createUnverifiedStudent('verify-b@rshd.test');

        $codeForA = $this->sendAndCaptureCode($userA);

        $this->postJson('/api/v1/email/verify', [
            'email' => $userB->email,
            'code' => $codeForA,
        ])->assertStatus(422);

        $this->assertNull($userB->fresh()->email_verified_at);
    }

    public function test_already_verified_user_can_obtain_session_without_replaying_otp(): void
    {
        $user = $this->createUnverifiedStudent('verify-done@rshd.test');
        $code = $this->sendAndCaptureCode($user);

        $this->postJson('/api/v1/email/verify', [
            'email' => $user->email,
            'code' => $code,
            'device_id' => 'verify-done-device',
        ])->assertOk();

        $this->postJson('/api/v1/email/verify', [
            'email' => $user->email,
            'code' => '999999',
            'device_id' => 'verify-done-device-2',
        ])
            ->assertOk()
            ->assertJsonStructure(['data' => ['token', 'user']]);
    }

    private function createUnverifiedStudent(string $email): User
    {
        $user = User::factory()->create([
            'email' => $email,
            'role' => UserRole::Student,
            'status' => UserStatus::Active,
            'email_verified_at' => null,
            'password' => Hash::make('Password123!'),
            'password_set_at' => now(),
        ]);

        $user->assignRole(Role::findByName(UserRole::Student->value, 'web'));

        return $user;
    }

    private function sendAndCaptureCode(User $user): string
    {
        app(StudentEmailVerificationService::class)->sendCode($user);

        $code = null;
        Mail::assertSent(StudentEmailVerificationCodeMail::class, function (StudentEmailVerificationCodeMail $mail) use (&$code) {
            $code = $mail->code;

            return true;
        });

        $this->assertNotNull($code);

        return $code;
    }
}
