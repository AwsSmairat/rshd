<?php

namespace Tests\Feature;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Http\Controllers\Api\V1\AuthController;
use App\Models\User;
use App\Services\AppleAuthService;
use App\Services\GoogleAuthService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class AuthOAuthTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_google_oauth_user_with_null_password_cannot_login_with_password(): void
    {
        $user = $this->createStudent([
            'email' => 'google-user@example.com',
            'google_id' => 'google-sub-123',
            'password' => null,
            'password_set_at' => null,
        ]);

        $response = $this->postJson('/api/v1/login', [
            'email' => $user->email,
            'password' => 'any-password',
            'device_id' => 'test-device-oauth',
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email']);

        $this->assertSame(
            AuthController::OAUTH_PASSWORD_LOGIN_MESSAGE,
            $response->json('errors.email.0'),
        );
    }

    public function test_apple_oauth_user_with_null_password_cannot_login_with_password(): void
    {
        $user = $this->createStudent([
            'email' => 'apple-user@example.com',
            'apple_id' => 'apple-sub-456',
            'password' => null,
            'password_set_at' => null,
        ]);

        $response = $this->postJson('/api/v1/login', [
            'email' => $user->email,
            'password' => 'any-password',
            'device_id' => 'test-device-oauth',
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email']);

        $this->assertSame(
            AuthController::OAUTH_PASSWORD_LOGIN_MESSAGE,
            $response->json('errors.email.0'),
        );
    }

    public function test_password_user_can_login_with_email_and_password(): void
    {
        $user = $this->createStudent([
            'email' => 'password-user@example.com',
            'password' => Hash::make('secret-password'),
            'password_set_at' => now(),
            'email_verified_at' => now(),
        ]);

        $response = $this->postJson('/api/v1/login', [
            'email' => $user->email,
            'password' => 'secret-password',
            'device_id' => 'test-device-password',
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => ['token', 'user'],
            ]);
    }

    public function test_google_auth_returns_sanctum_token_for_existing_google_user(): void
    {
        $user = $this->createStudent([
            'email' => 'google-user@example.com',
            'google_id' => 'google-sub-123',
            'password' => null,
            'password_set_at' => null,
            'email_verified_at' => now(),
        ]);

        $this->mock(GoogleAuthService::class, function ($mock) use ($user): void {
            $mock->shouldReceive('verifyIdToken')
                ->once()
                ->with('valid-google-token')
                ->andReturn([
                    'google_id' => 'google-sub-123',
                    'email' => $user->email,
                    'name' => $user->name,
                    'email_verified' => true,
                ]);

            $mock->shouldReceive('resolveStudentUser')
                ->once()
                ->andReturn($user->fresh());
        });

        $response = $this->postJson('/api/v1/auth/google', [
            'id_token' => 'valid-google-token',
            'device_id' => 'test-device-google',
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => ['token', 'user'],
            ]);
    }

    public function test_apple_auth_returns_sanctum_token_for_existing_apple_user(): void
    {
        $user = $this->createStudent([
            'email' => 'apple-user@example.com',
            'apple_id' => 'apple-sub-456',
            'password' => null,
            'password_set_at' => null,
            'email_verified_at' => now(),
        ]);

        $this->mock(AppleAuthService::class, function ($mock) use ($user): void {
            $mock->shouldReceive('verifyIdentityToken')
                ->once()
                ->with('valid-apple-token')
                ->andReturn([
                    'apple_id' => 'apple-sub-456',
                    'email' => $user->email,
                    'name' => $user->name,
                    'email_verified' => true,
                ]);

            $mock->shouldReceive('resolveStudentUser')
                ->once()
                ->andReturn($user->fresh());
        });

        $response = $this->postJson('/api/v1/auth/apple', [
            'identity_token' => 'valid-apple-token',
            'device_id' => 'test-device-apple',
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => ['token', 'user'],
            ]);
    }

    public function test_google_auth_does_not_link_existing_password_account_by_email(): void
    {
        $this->createStudent([
            'email' => 'shared@example.com',
            'password' => Hash::make('secret-password'),
            'password_set_at' => now(),
        ]);

        $service = app(GoogleAuthService::class);

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage(
            'An account with this email already exists. Please sign in with your email and password.',
        );

        $service->resolveStudentUser([
            'google_id' => 'new-google-sub',
            'email' => 'shared@example.com',
            'name' => 'Shared User',
            'email_verified' => true,
        ]);
    }

    public function test_apple_auth_rejects_existing_google_account_with_same_email(): void
    {
        $this->createStudent([
            'email' => 'shared@example.com',
            'google_id' => 'google-sub-999',
            'password' => null,
            'password_set_at' => null,
        ]);

        $service = app(AppleAuthService::class);

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage(
            AuthController::OAUTH_PASSWORD_LOGIN_MESSAGE,
        );

        $service->resolveStudentUser([
            'apple_id' => 'apple-sub-999',
            'email' => 'shared@example.com',
            'name' => 'Shared User',
            'email_verified' => true,
        ]);
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
}
