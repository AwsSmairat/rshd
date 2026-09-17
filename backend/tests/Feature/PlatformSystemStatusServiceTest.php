<?php

namespace Tests\Feature;

use App\Services\Bunny\BunnyStreamService;
use App\Services\PlatformSystemStatusService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class PlatformSystemStatusServiceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Cache::forget('scheduler_last_run');
        Cache::forget('queue_worker_last_run');
    }

    public function test_bunny_video_status_uses_bunny_configuration(): void
    {
        config(['video.provider' => 'bunny']);

        $this->mock(BunnyStreamService::class, function ($mock): void {
            $mock->shouldReceive('isConfigured')->once()->andReturnTrue();
        });

        $row = collect(app(PlatformSystemStatusService::class)->rows())
            ->firstWhere('label', 'خدمة الفيديو');

        $this->assertSame('متصل', $row['status']);
        $this->assertSame('success', $row['tone']);
    }

    public function test_scheduler_status_uses_recent_heartbeat(): void
    {
        Cache::put('scheduler_last_run', now(), now()->addMinutes(10));

        $row = collect(app(PlatformSystemStatusService::class)->rows())
            ->firstWhere('label', 'Scheduler');

        $this->assertSame('متصل', $row['status']);
        $this->assertSame('success', $row['tone']);
    }

    public function test_database_queue_worker_requires_recent_heartbeat(): void
    {
        config(['queue.default' => 'database']);

        $service = app(PlatformSystemStatusService::class);

        $stopped = collect($service->rows())->firstWhere('label', 'Queue worker');
        $this->assertSame('متوقف', $stopped['status']);

        Cache::put('queue_worker_last_run', now(), now()->addMinutes(10));

        $running = collect($service->rows())->firstWhere('label', 'Queue worker');
        $this->assertSame('متصل', $running['status']);
        $this->assertSame('success', $running['tone']);
    }
}
