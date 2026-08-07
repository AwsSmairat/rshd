<?php

namespace App\Jobs;

use App\Models\Video;
use App\Services\Bunny\BunnyStreamService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;
use Throwable;

class SyncBunnyVideoStatusJob implements ShouldQueue
{
    use Queueable;

    public int $tries = 10;

    public function __construct(public int $videoId) {}

    public function handle(BunnyStreamService $bunnyStream): void
    {
        $video = Video::query()->find($this->videoId);

        if ($video === null || $video->external_video_id === null || $video->external_video_id === '') {
            return;
        }

        if (! $bunnyStream->isConfigured()) {
            return;
        }

        try {
            $bunnyStream->syncVideoStatus($video);
        } catch (Throwable $exception) {
            Log::warning('bunny.stream.sync.failed', [
                'video_id' => $video->id,
                'external_video_id' => $video->external_video_id,
                'reason' => $exception->getMessage(),
            ]);

            throw $exception;
        }
    }
}
