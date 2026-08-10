<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class HealthCheckTest extends TestCase
{
    use RefreshDatabase;

    public function test_health_endpoint_returns_safe_json_without_secrets(): void
    {
        config(['queue.default' => 'database']);

        $response = $this->getJson('/health');

        $response->assertOk()
            ->assertJsonStructure([
                'status',
                'environment',
                'checks' => [
                    'database' => ['status', 'detail'],
                    'cache' => ['status', 'detail'],
                    'queue' => ['status', 'detail'],
                ],
            ]);

        $body = $response->getContent();
        $this->assertStringNotContainsString('DB_PASSWORD', (string) $body);
        $this->assertStringNotContainsString('BUNNY_', (string) $body);
        $this->assertStringNotContainsString('APP_KEY', (string) $body);
    }

    public function test_health_fails_queue_check_when_sync_driver(): void
    {
        config(['queue.default' => 'sync']);

        $this->getJson('/health')
            ->assertStatus(503)
            ->assertJsonPath('checks.queue.status', 'fail');
    }
}
