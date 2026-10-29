<?php

namespace App\Jobs;

use App\Enums\VideoStatus;
use App\Models\Video;
use App\Services\Bunny\BunnyStreamService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Cache;
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

    public function __construct(public int $videoId)
    {
        $this->onConnection('bunny_uploads')
            ->onQueue('bunny-uploads');
    }

    public function handle(BunnyStreamService $bunnyStream): void
    {
        // Shared atomic lock: one Bunny upload per local video at a time.
        // The lease exceeds the job timeout; queue timing must also be aligned.
        $lock = Cache::lock(
            'bunny:video:upload:'.$this->videoId,
            $this->timeout + 300
        );

        if (! $lock->get()) {
            Log::info('bunny.stream.upload.lock_busy', [
                'video_id' => $this->videoId,
            ]);

            // Keep the queued job instead of silently losing it.
            // Retry after the current upload's maximum lock lease.
            $this->release($this->timeout + 300);

            return;
        }

        try {
            $this->handleWithLock($bunnyStream);
        } finally {
            $lock->release();
        }
    }

    private function handleWithLock(BunnyStreamService $bunnyStream): void
    {
        $video = Video::query()->find($this->videoId);

        if ($video === null) {
            return;
        }

        if ($video->status === VideoStatus::Ready && filled($video->external_video_id)) {
            return;
        }

        try {
            if (! $bunnyStream->shouldUploadLocalVideo($video)) {
                SyncBunnyVideoStatusJob::dispatch($this->videoId)->delay(now()->addSeconds(30));

                return;
            }

            $bunnyStream->uploadLocalVideo($video);
            SyncBunnyVideoStatusJob::dispatch($this->videoId)->delay(now()->addSeconds(30));
        } catch (Throwable $exception) {
            // An older job must not overwrite a newer Ready status.
            // Also protect a replacement upload with a different path or GUID.
            Video::query()
                ->whereKey($video->id)
                ->where('storage_provider', 'bunny')
                ->where('video_path', $video->video_path)
                ->where('external_video_id', $video->external_video_id)
                ->whereIn('status', [
                    VideoStatus::Uploading->value,
                    VideoStatus::Processing->value,
                ])
                ->update(['status' => VideoStatus::Failed->value]);

            Log::warning('bunny.stream.upload.failed', [
                'video_id' => $video->id,
                'reason' => $exception->getMessage(),
            ]);

            throw $exception;
        }
    }
}
