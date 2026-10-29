<?php

namespace App\Console\Commands;

use App\Jobs\SyncBunnyVideoStatusJob;
use App\Models\Video;
use App\Services\Bunny\BunnyStreamService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;
use Throwable;

class ReconcileBunnyVideoStatuses extends Command
{
    protected $signature = 'bunny:reconcile-video-statuses
        {--dry-run : Inspect candidates without dispatching jobs}';

    protected $description =
        'Reconcile stale Bunny Stream video statuses safely.';

    public function handle(BunnyStreamService $bunnyStream): int
    {
        if (! $bunnyStream->isConfigured()) {
            $this->warn('Bunny Stream is not configured.');

            return self::FAILURE;
        }

        $videos = Video::query()
            ->where('storage_provider', 'bunny')
            ->whereNotNull('external_video_id')
            ->where('external_video_id', '!=', '')
            ->where('updated_at', '<=', now()->subMinutes(10))
            ->where(function ($query): void {
                $query
                    ->whereIn('status', [
                        'uploading',
                        'processing',
                    ])
                    ->orWhere(function ($query): void {
                        $query
                            ->where('status', 'ready')
                            ->where(function ($query): void {
                                $query
                                    ->whereNull('duration_seconds')
                                    ->orWhere(
                                        'duration_seconds',
                                        '<=',
                                        0
                                    );
                            });
                    });
            })
            ->orderBy('updated_at')
            ->orderBy('id')
            ->limit(100)
            ->get();

        if ($this->option('dry-run')) {
            $this->info(
                'Eligible stale videos: '.$videos->count()
            );

            return self::SUCCESS;
        }

        $dispatched = 0;

        foreach ($videos as $video) {
            if ($dispatched >= 20) {
                break;
            }

            $guid = trim((string) $video->external_video_id);

            if ($guid === '') {
                continue;
            }

            $key = 'bunny:stream:reconcile:'
                .$video->id.':'.sha1($guid);

            if (! Cache::add($key, 1, 600)) {
                continue;
            }

            try {
                SyncBunnyVideoStatusJob::dispatch(
                    $video->id,
                    0,
                    $guid,
                    false
                );

                $dispatched++;
            } catch (Throwable $exception) {
                Cache::forget($key);

                throw $exception;
            }
        }

        $this->info(
            'Bunny reconciliation jobs dispatched: '.$dispatched
        );

        return self::SUCCESS;
    }
}
