<?php

namespace App\Jobs;

use App\Enums\VideoStatus;
use App\Models\Video;
use App\Services\Bunny\BunnyStreamService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;
use Throwable;

class UploadVideoToBunnyJob implements ShouldQueue
{
    use Queueable;

    public int $tries = 3;

    public int $timeout = 7200;

    /**
     * @return array<int, int>
     */
    public function backoff(): array
    {
        return [30, 120, 300];
    }

    public function __construct(public int $videoId) {}

    public function handle(BunnyStreamService $bunnyStream): void
    {
        $video = Video::query()->find($this->videoId);

        if ($video === null) {
            return;
        }

        if ($video->external_video_id !== null && $video->external_video_id !== '') {
            return;
        }

        try {
            $bunnyStream->uploadLocalVideo($video);
            SyncBunnyVideoStatusJob::dispatch($this->videoId)->delay(now()->addSeconds(30));
        } catch (Throwable $exception) {
            $video->update(['status' => VideoStatus::Failed]);

            Log::warning('bunny.stream.upload.failed', [
                'video_id' => $video->id,
                'reason' => $exception->getMessage(),
            ]);

            throw $exception;
        }
    }
}
