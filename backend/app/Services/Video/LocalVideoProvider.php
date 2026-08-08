<?php

namespace App\Services\Video;

use App\Contracts\VideoProviderInterface;
use App\Models\User;
use App\Models\Video;
use App\Services\PlaybackExpiryResolver;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class LocalVideoProvider implements VideoProviderInterface
{
    public function __construct(
        protected PlaybackExpiryResolver $expiryResolver,
    ) {}

    public function supports(Video $video): bool
    {
        return $video->storage_provider !== 'bunny';
    }

    /**
     * @return array{url: string, expires_at: Carbon}
     */
    public function generateSignedPlaybackUrl(Video $video, User $user): array
    {
        if ($this->shouldUseUnsignedDevFallback($video)) {
            $url = $video->resolvedExternalVideoUrl();

            if ($url === null || $url === '') {
                throw new RuntimeException('Video source is not available.');
            }

            return [
                'url' => $url,
                'expires_at' => now()->addHours(24),
                'type' => 'hls',
            ];
        }

        if ($video->video_path !== null && $video->video_path !== '') {
            if (! $video->hasLocalStoredFile()) {
                throw new RuntimeException('Video file was not found on storage.');
            }
        } elseif ($video->resolvedExternalVideoUrl() === null) {
            throw new RuntimeException('Video source is not available.');
        }

        return $this->buildSignedStreamPayload($video, $user);
    }

    /**
     * @return array{url: string, expires_at: Carbon}
     */
    protected function buildSignedStreamPayload(Video $video, User $user): array
    {
        $expiresAt = $this->expiryResolver->resolve($user, $video);
        $token = $this->buildStreamToken($video->id, $user->id, $expiresAt);

        $url = url('/api/v1/videos/'.$video->id.'/stream').'?'.http_build_query([
            'uid' => $user->id,
            'expires' => $expiresAt->getTimestamp(),
            'token' => $token,
        ]);

        return [
            'url' => $url,
            'expires_at' => $expiresAt,
            'type' => 'hls',
        ];
    }

    public function buildStreamToken(int $videoId, int $userId, Carbon $expiresAt): string
    {
        $payload = $videoId.'|'.$userId.'|'.$expiresAt->getTimestamp();

        return hash_hmac('sha256', $payload, $this->signingKey());
    }

    public function validateStreamToken(int $videoId, int $userId, int $expiresTimestamp, string $token): bool
    {
        if ($expiresTimestamp < now()->getTimestamp()) {
            return false;
        }

        $expected = $this->buildStreamToken(
            $videoId,
            $userId,
            Carbon::createFromTimestamp($expiresTimestamp),
        );

        return hash_equals($expected, $token);
    }

    protected function shouldUseUnsignedDevFallback(Video $video): bool
    {
        if (config('video.signed_playback', true)) {
            return false;
        }

        if (! app()->environment('local', 'testing')) {
            Log::critical('video.playback.unsigned_fallback_blocked', [
                'video_id' => $video->id,
            ]);

            return false;
        }

        return $video->video_path === null || $video->video_path === '';
    }

    protected function signingKey(): string
    {
        return (string) (config('video.signing_key') ?: config('app.key'));
    }
}
