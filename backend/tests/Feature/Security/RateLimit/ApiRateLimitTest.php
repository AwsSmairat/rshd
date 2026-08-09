<?php

namespace Tests\Feature\Security\RateLimit;

use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\RateLimiter;
use Tests\TestCase;

/**
 * @group security
 */
class ApiRateLimitTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
        RateLimiter::clear('auth-login');
        RateLimiter::clear('register');
    }

    public function test_login_is_throttled_after_repeated_attempts(): void
    {
        for ($i = 0; $i < 10; $i++) {
            $this->postJson('/api/v1/login', [
                'email' => 'throttle-login@rshd.test',
                'password' => 'wrong-password',
            ]);
        }

        $this->postJson('/api/v1/login', [
            'email' => 'throttle-login@rshd.test',
            'password' => 'wrong-password',
        ])->assertStatus(429);
    }

    public function test_public_settings_respects_guest_baseline(): void
    {
        RateLimiter::clear('api-guest');

        for ($i = 0; $i < 60; $i++) {
            $this->getJson('/api/v1/settings/public')->assertOk();
        }

        $this->getJson('/api/v1/settings/public')->assertStatus(429);
    }
}
