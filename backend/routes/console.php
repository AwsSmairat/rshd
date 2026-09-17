<?php

use App\Jobs\QueueWorkerHeartbeatJob;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');


Schedule::call(static function (): void {
    cache()->put('scheduler_last_run', now(), now()->addMinutes(10));
})->everyMinute()->name('scheduler-heartbeat');

Schedule::job(new QueueWorkerHeartbeatJob)
    ->everyMinute()
    ->name('queue-worker-heartbeat');

Schedule::command('platform:backup')->dailyAt('02:00');
Schedule::command('platform:prune-audit-logs')->dailyAt('03:00');
