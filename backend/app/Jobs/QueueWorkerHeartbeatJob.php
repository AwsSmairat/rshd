<?php

namespace App\Jobs;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class QueueWorkerHeartbeatJob implements ShouldQueue
{
    use Queueable;

    public function handle(): void
    {
        cache()->put('queue_worker_last_run', now(), now()->addMinutes(10));
    }
}
