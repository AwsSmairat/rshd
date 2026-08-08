<?php

namespace App\Services;

use App\Contracts\VideoProviderInterface;
use App\Enums\VideoStatus;
use App\Models\User;
use App\Models\Video;
use App\Services\Video\BunnyStreamVideoProvider;
use App\Services\Video\LocalVideoProvider;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class VideoPlaybackService
{
    public function __construct(
        protected VideoAccessService $access,
        protected LocalVideoProvider $localProvider,
        protected BunnyStreamVideoProvider $bunnyProvider,
    ) {}

    /**
     * @return array{url: string, expires_at: Carbon}|null
     */
    public function generatePlaybackUrl(Video $video, User $user): ?array
    {
        if (! $this->access->canPlay($user, $video)) {
            return null;
        }

        if ($video->status !== VideoStatus::Ready) {
            return null;
        }

        try {
            return $this->resolveProvider($video)->generateSignedPlaybackUrl($video, $user);
        } catch (RuntimeException $exception) {
            Log::warning('video.playback.failed', [
                'video_id' => $video->id,
                'user_id' => $user->id,
                'provider' => $video->storage_provider,
                'reason' => $exception->getMessage(),
            ]);

            return null;
        }
    }

    public function validateLocalStreamToken(
        Video $video,
        int $userId,
        int $expiresTimestamp,
        string $token,
    ): bool {
        return $this->localProvider->validateStreamToken(
            $video->id,
            $userId,
            $expiresTimestamp,
            $token,
        );
    }

    protected function resolveProvider(Video $video): VideoProviderInterface
    {
        if ($video->storage_provider === 'bunny') {
            if ($this->shouldServeLocalFallback($video)) {
                Log::info('video.playback.bunny_local_fallback', [
                    'video_id' => $video->id,
                ]);

                return $this->localProvider;
            }

            if ($this->bunnyProvider->isConfigured()) {
                return $this->bunnyProvider;
            }

            if (app()->environment('production')) {
                throw new RuntimeException('Bunny Stream playback is not configured.');
            }

            if ($video->hasLocalStoredFile()) {
                Log::warning('video.playback.bunny_dev_local_fallback', [
                    'video_id' => $video->id,
                ]);

                return $this->localProvider;
            }

            throw new RuntimeException('Bunny Stream playback is not configured.');
        }

        return $this->localProvider;
    }

    protected function shouldServeLocalFallback(Video $video): bool
    {
        if (! config('video.bunny.local_fallback', false)) {
            return false;
        }

        return $video->hasLocalStoredFile();
    }
}
