<?php

namespace Tests\Feature;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Mail\StudentPasswordResetCodeMail;
use App\Models\StudentPasswordResetCode;
use App\Models\User;
use App\Services\StudentPasswordResetService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class PasswordResetTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
        Cache::flush();
    }

    public function test_student_can_reset_password_with_full_otp_flow(): void
    {
        Mail::fake();

        $user = $this->createStudent([
            'email' => 'student@rshdacademy.com',
            'password' => Hash::make('Oldpassword1'),
            'password_set_at' => now(),
        ]);

        $code = $this->requestResetAndCaptureCode($user->email);

        $resetToken = $this->verifyAndCaptureResetToken($user->email, $code);

        $this->postJson('/api/v1/password/reset', [
            'email' => $user->email,
            'reset_token' => $resetToken,
            'password' => 'Newpassword1',
            'password_confirmation' => 'Newpassword1',
        ])->assertOk()->assertJsonPath('success', true);

        $this->assertTrue(Hash::check('Newpassword1', $user->fresh()->password));

        $this->postJson('/api/v1/login', [
            'email' => $user->email,
            'password' => 'Newpassword1',
            'device_id' => 'reset-test-device',
        ])->assertOk();

        $this->postJson('/api/v1/login', [
            'email' => $user->email,
            'password' => 'Oldpassword1',
            'device_id' => 'reset-test-device',
        ])->assertStatus(422);
    }

    public function test_forgot_returns_generic_success_for_unknown_email(): void
    {
        Mail::fake();

        $response = $this->postJson('/api/v1/password/forgot', [
            'email' => 'missing@example.com',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', StudentPasswordResetService::GENERIC_REQUEST_MESSAGE);

        Mail::assertNothingSent();
    }

    public function test_forgot_existing_and_unknown_emails_have_similar_success_responses(): void
    {
        Mail::fake();

        $user = $this->createStudent([
            'email' => 'student@rshdacademy.com',
            'password' => Hash::make('Oldpassword1'),
            'password_set_at' => now(),
        ]);

        $existing = $this->postJson('/api/v1/password/forgot', ['email' => $user->email]);
        $missing = $this->postJson('/api/v1/password/forgot', ['email' => 'ghost@example.com']);

        $existing->assertOk()->assertJsonPath('success', true);
        $missing->assertOk()->assertJsonPath('success', true);
        $this->assertSame(
            $existing->json('message'),
            $missing->json('message'),
        );
        $this->assertStringNotContainsString('not found', strtolower((string) $existing->json('message')));
        $this->assertStringNotContainsString('غير موجود', (string) $missing->json('message'));
    }

    public function test_otp_and_reset_token_are_stored_hashed_not_plain(): void
    {
        Mail::fake();

        $user = $this->createStudent([
            'email' => 'student@rshdacademy.com',
            'password' => Hash::make('Oldpassword1'),
            'password_set_at' => now(),
        ]);

        $code = $this->requestResetAndCaptureCode($user->email);
        $record = StudentPasswordResetCode::query()->where('user_id', $user->id)->latest('id')->first();

        $this->assertNotSame($code, $record->code_hash);
        $this->assertTrue(Hash::check($code, $record->code_hash));

        $resetToken = $this->verifyAndCaptureResetToken($user->email, $code);
        $record->refresh();

        $this->assertNotSame($resetToken, $record->reset_token_hash);
        $this->assertTrue(Hash::check($resetToken, (string) $record->reset_token_hash));
    }

    public function test_wrong_otp_is_rejected_and_increments_attempts(): void
    {
        Mail::fake();

        $user = $this->createStudent([
            'email' => 'student@rshdacademy.com',
            'password' => Hash::make('Oldpassword1'),
            'password_set_at' => now(),
        ]);

        $this->requestResetAndCaptureCode($user->email);

        $this->postJson('/api/v1/password/verify', [
            'email' => $user->email,
            'code' => '000000',
        ])->assertStatus(422);

        $record = StudentPasswordResetCode::query()->where('user_id', $user->id)->latest('id')->first();
        $this->assertSame(1, $record->attempts);
    }

    public function test_expired_otp_is_rejected(): void
    {
        Mail::fake();

        $user = $this->createStudent([
            'email' => 'student@rshdacademy.com',
            'password' => Hash::make('Oldpassword1'),
            'password_set_at' => now(),
        ]);

        $code = $this->requestResetAndCaptureCode($user->email);

        $this->travel(11)->minutes();

        $this->postJson('/api/v1/password/verify', [
            'email' => $user->email,
            'code' => $code,
        ])->assertStatus(422);
    }

    public function test_max_otp_attempts_blocks_further_verification(): void
    {
        Mail::fake();

        $user = $this->createStudent([
            'email' => 'student@rshdacademy.com',
            'password' => Hash::make('Oldpassword1'),
            'password_set_at' => now(),
        ]);

        $this->requestResetAndCaptureCode($user->email);

        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/v1/password/verify', [
                'email' => $user->email,
                'code' => '000000',
            ]);
        }

        $this->postJson('/api/v1/password/verify', [
            'email' => $user->email,
            'code' => '000000',
        ])->assertStatus(422)
            ->assertJsonPath('message', 'تم تجاوز عدد المحاولات');
    }

    public function test_resend_invalidates_previous_otp(): void
    {
        Mail::fake();

        $user = $this->createStudent([
            'email' => 'student@rshdacademy.com',
            'password' => Hash::make('Oldpassword1'),
            'password_set_at' => now(),
        ]);

        $firstCode = $this->requestResetAndCaptureCode($user->email);

        $this->travel(61)->seconds();

        $secondCode = $this->resendAndCaptureCode($user->email);
        $this->assertNotSame($firstCode, $secondCode);

        $this->postJson('/api/v1/password/verify', [
            'email' => $user->email,
            'code' => $firstCode,
        ])->assertStatus(422);

        $this->postJson('/api/v1/password/verify', [
            'email' => $user->email,
            'code' => $secondCode,
        ])->assertOk();
    }

    public function test_resend_respects_cooldown(): void
    {
        Mail::fake();

        $user = $this->createStudent([
            'email' => 'student@rshdacademy.com',
            'password' => Hash::make('Oldpassword1'),
            'password_set_at' => now(),
        ]);

        $this->requestResetAndCaptureCode($user->email);

        $this->postJson('/api/v1/password/resend', [
            'email' => $user->email,
        ])->assertStatus(429);
    }

    public function test_reset_token_cannot_be_used_twice(): void
    {
        Mail::fake();

        $user = $this->createStudent([
            'email' => 'student@rshdacademy.com',
            'password' => Hash::make('Oldpassword1'),
            'password_set_at' => now(),
        ]);

        $code = $this->requestResetAndCaptureCode($user->email);
        $resetToken = $this->verifyAndCaptureResetToken($user->email, $code);

        $payload = [
            'email' => $user->email,
            'reset_token' => $resetToken,
            'password' => 'Newpassword1',
            'password_confirmation' => 'Newpassword1',
        ];

        $this->postJson('/api/v1/password/reset', $payload)->assertOk();
        $this->postJson('/api/v1/password/reset', $payload)->assertStatus(422);
    }

    public function test_expired_reset_token_is_rejected(): void
    {
        Mail::fake();

        $user = $this->createStudent([
            'email' => 'student@rshdacademy.com',
            'password' => Hash::make('Oldpassword1'),
            'password_set_at' => now(),
        ]);

        $code = $this->requestResetAndCaptureCode($user->email);
        $resetToken = $this->verifyAndCaptureResetToken($user->email, $code);

        $this->travel(16)->minutes();

        $this->postJson('/api/v1/password/reset', [
            'email' => $user->email,
            'reset_token' => $resetToken,
            'password' => 'Newpassword1',
            'password_confirmation' => 'Newpassword1',
        ])->assertStatus(422);
    }

    public function test_password_policy_and_confirmation_are_enforced(): void
    {
        Mail::fake();

        $user = $this->createStudent([
            'email' => 'student@rshdacademy.com',
            'password' => Hash::make('Oldpassword1'),
            'password_set_at' => now(),
        ]);

        $code = $this->requestResetAndCaptureCode($user->email);
        $resetToken = $this->verifyAndCaptureResetToken($user->email, $code);

        $this->postJson('/api/v1/password/reset', [
            'email' => $user->email,
            'reset_token' => $resetToken,
            'password' => 'weak',
            'password_confirmation' => 'weak',
        ])->assertStatus(422);

        $this->postJson('/api/v1/password/reset', [
            'email' => $user->email,
            'reset_token' => $resetToken,
            'password' => 'Newpassword1',
            'password_confirmation' => 'Mismatch1',
        ])->assertStatus(422);
    }

    public function test_password_reset_revokes_existing_sanctum_tokens(): void
    {
        Mail::fake();

        $user = $this->createStudent([
            'email' => 'student@rshdacademy.com',
            'password' => Hash::make('Oldpassword1'),
            'password_set_at' => now(),
        ]);

        $token = $user->createToken('device-session')->plainTextToken;
        $this->withToken($token)->getJson('/api/v1/me')->assertOk();

        $code = $this->requestResetAndCaptureCode($user->email);
        $resetToken = $this->verifyAndCaptureResetToken($user->email, $code);

        $this->postJson('/api/v1/password/reset', [
            'email' => $user->email,
            'reset_token' => $resetToken,
            'password' => 'Newpassword1',
            'password_confirmation' => 'Newpassword1',
        ])->assertOk();

        $this->assertSame(0, $user->fresh()->tokens()->count());
        $this->assertDatabaseMissing('personal_access_tokens', [
            'tokenable_id' => $user->id,
            'tokenable_type' => User::class,
        ]);
    }

    public function test_email_normalization_prevents_duplicate_rate_limit_keys(): void
    {
        Mail::fake();

        $user = $this->createStudent([
            'email' => 'student@rshdacademy.com',
            'password' => Hash::make('Oldpassword1'),
            'password_set_at' => now(),
        ]);

        $this->postJson('/api/v1/password/forgot', ['email' => 'Student@RshdAcademy.com'])
            ->assertOk();

        $this->assertSame(1, (int) Cache::get('password_reset_forgot:email:student@rshdacademy.com', 0));

        $this->postJson('/api/v1/password/forgot', ['email' => ' student@rshdacademy.com '])
            ->assertOk();

        $this->assertSame(2, (int) Cache::get('password_reset_forgot:email:student@rshdacademy.com', 0));
        $this->assertNull(Cache::get('password_reset_forgot:email:Student@RshdAcademy.com'));
    }

    public function test_forgot_rate_limit_by_email(): void
    {
        Mail::fake();

        $user = $this->createStudent([
            'email' => 'student@rshdacademy.com',
            'password' => Hash::make('Oldpassword1'),
            'password_set_at' => now(),
        ]);

        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/v1/password/forgot', ['email' => $user->email])->assertOk();
        }

        $this->postJson('/api/v1/password/forgot', ['email' => $user->email])
            ->assertStatus(429);
    }

    public function test_forgot_rate_limit_by_ip_for_many_emails(): void
    {
        Mail::fake();

        for ($i = 0; $i < 20; $i++) {
            $this->postJson('/api/v1/password/forgot', [
                'email' => "user{$i}@example.com",
            ])->assertOk();
        }

        $this->postJson('/api/v1/password/forgot', [
            'email' => 'another@example.com',
        ])->assertStatus(429);
    }

    public function test_verify_does_not_reveal_unknown_user(): void
    {
        $this->postJson('/api/v1/password/verify', [
            'email' => 'ghost@example.com',
            'code' => '123456',
        ])->assertStatus(404);
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    private function createStudent(array $attributes = []): User
    {
        $user = User::factory()->create(array_merge([
            'role' => UserRole::Student,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
        ], $attributes));

        $role = Role::findByName(UserRole::Student->value, 'web');
        $user->assignRole($role);

        return $user;
    }

    private function requestResetAndCaptureCode(string $email): string
    {
        $this->postJson('/api/v1/password/forgot', ['email' => $email])->assertOk();

        $code = null;
        Mail::assertSent(StudentPasswordResetCodeMail::class, function (StudentPasswordResetCodeMail $mail) use (&$code) {
            $code = $mail->code;

            return true;
        });

        $this->assertNotNull($code);

        return $code;
    }

    private function resendAndCaptureCode(string $email): string
    {
        $this->postJson('/api/v1/password/resend', ['email' => $email])->assertOk();

        $code = null;
        Mail::assertSent(StudentPasswordResetCodeMail::class, function (StudentPasswordResetCodeMail $mail) use (&$code) {
            $code = $mail->code;

            return true;
        });

        $this->assertNotNull($code);

        return $code;
    }

    private function verifyAndCaptureResetToken(string $email, string $code): string
    {
        $response = $this->postJson('/api/v1/password/verify', [
            'email' => $email,
            'code' => $code,
        ])->assertOk();

        $token = $response->json('data.reset_token');
        $this->assertNotEmpty($token);

        return $token;
    }
}
