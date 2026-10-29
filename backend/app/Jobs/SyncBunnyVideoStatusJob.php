<?php

namespace App\Jobs;

use App\Enums\VideoStatus;
use App\Models\Video;
use App\Services\Bunny\BunnyStreamService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use RuntimeException;
use Throwable;

class SyncBunnyVideoStatusJob implements ShouldQueue
{
    use Queueable;

    public int $tries = 10;

    public const POLL_DELAY_SECONDS = 120;

    public const MAX_POLLS = 90;

    public function __construct(
        public int $videoId,
        public int $pollAttempt = 0,
        public ?string $expectedGuid = null,
        public bool $scheduleFollowUp = true,
    ) {}

    public function handle(BunnyStreamService $bunnyStream): void
    {
        $lock = Cache::lock(
            'bunny:stream:status:'.$this->videoId,
            180
        );

        if (! $lock->get()) {
            return;
        }

        try {
            $video = Video::query()->find($this->videoId);

            if ($video === null) {
                return;
            }

            $guid = trim((string) $video->external_video_id);

            if ($guid === '') {
                return;
            }

            if (
                $this->expectedGuid !== null &&
                $this->expectedGuid !== $guid
            ) {
                return;
            }

            if (
                $video->status === VideoStatus::Failed ||
                (
                    $video->status === VideoStatus::Ready &&
                    (int) $video->duration_seconds > 0
                )
            ) {
                return;
            }

            if (! $bunnyStream->isConfigured()) {
                throw new RuntimeException(
                    'Bunny Stream sync is not configured.'
                );
            }

            $updated = $bunnyStream->syncVideoStatus($video);

            if ($updated->external_video_id !== $guid) {
                return;
            }

            $needsDuration = (
                $updated->status === VideoStatus::Ready &&
                (int) $updated->duration_seconds <= 0
            );

            if (
                ! $needsDuration &&
                ! in_array($updated->status, [
                    VideoStatus::Uploading,
                    VideoStatus::Processing,
                ], true)
            ) {
                return;
            }

            // Reconciliation checks once; only normal polling schedules follow-ups.
            if (! $this->scheduleFollowUp) {
                return;
            }

            if ($this->pollAttempt >= self::MAX_POLLS) {
                Log::warning('bunny.stream.sync.poll_limit', [
                    'video_id' => $this->videoId,
                    'poll_attempt' => $this->pollAttempt,
                ]);

                return;
            }

            $reservationKey =
                'bunny:stream:sync:next:'.$this->videoId.':'.$guid.':'.($this->pollAttempt + 1);

            if (! Cache::add(
                $reservationKey,
                1,
                self::POLL_DELAY_SECONDS * 3
            )) {
                return;
            }

            try {
                self::dispatch(
                    $this->videoId,
                    $this->pollAttempt + 1,
                    $guid
                )->delay(
                    now()->addSeconds(self::POLL_DELAY_SECONDS)
                );
            } catch (Throwable $exception) {
                Cache::forget($reservationKey);
                throw $exception;
            }

        } catch (Throwable $exception) {
            Log::warning('bunny.stream.sync.failed', [
                'video_id' => $this->videoId,
                'poll_attempt' => $this->pollAttempt,
                'reason' => $exception->getMessage(),
            ]);

            throw $exception;
        } finally {
            $lock->release();
        }
    }
}
