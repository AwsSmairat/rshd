<?php

namespace Tests\Feature\Security\Auth;

use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

/**
 * @group security
 */
class LogoutSecurityTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_authenticated_student_can_logout(): void
    {
        $student = $this->createStudent(['email' => 'logout-a@rshd.test']);
        $token = $student->createToken('api')->plainTextToken;

        $this->withToken($token)
            ->postJson('/api/v1/logout')
            ->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_logout_invalidates_current_token_only(): void
    {
        $student = $this->createStudent(['email' => 'logout-b@rshd.test']);
        $accessToken = $student->createToken('api');
        $token = $accessToken->plainTextToken;

        $this->withToken($token)->postJson('/api/v1/logout')->assertOk();

        $this->assertDatabaseMissing('personal_access_tokens', [
            'id' => $accessToken->accessToken->id,
        ]);

        $this->app['auth']->forgetGuards();

        $this->withToken($token)->getJson('/api/v1/me')->assertUnauthorized();
    }

    public function test_logout_without_auth_returns_unauthorized(): void
    {
        $this->postJson('/api/v1/logout')->assertUnauthorized();
    }

    public function test_logout_does_not_revoke_other_users_tokens(): void
    {
        $studentA = $this->createStudent(['email' => 'logout-c@rshd.test']);
        $studentB = $this->createStudent(['email' => 'logout-d@rshd.test']);

        $tokenA = $studentA->createToken('api')->plainTextToken;
        $tokenB = $studentB->createToken('api')->plainTextToken;

        $this->withToken($tokenA)->postJson('/api/v1/logout')->assertOk();

        $this->withToken($tokenB)->getJson('/api/v1/me')->assertOk();
    }

    public function test_logout_revokes_only_current_token_when_multiple_exist(): void
    {
        $student = $this->createStudent(['email' => 'logout-e@rshd.test']);
        $accessTokenA = $student->createToken('device-a');
        $tokenA = $accessTokenA->plainTextToken;
        $accessTokenB = $student->createToken('device-b');
        $tokenB = $accessTokenB->plainTextToken;

        $this->withToken($tokenA)->postJson('/api/v1/logout')->assertOk();

        $this->assertDatabaseMissing('personal_access_tokens', [
            'id' => $accessTokenA->accessToken->id,
        ]);
        $this->assertDatabaseHas('personal_access_tokens', [
            'id' => $accessTokenB->accessToken->id,
        ]);

        $this->app['auth']->forgetGuards();

        $this->withToken($tokenA)->getJson('/api/v1/me')->assertUnauthorized();
        $this->withToken($tokenB)->getJson('/api/v1/me')->assertOk();
    }
}
