<?php

namespace App\Services\Video;

use App\Contracts\VideoProviderInterface;
use App\Models\User;
use App\Models\Video;
use App\Services\Bunny\BunnyCdnTokenSigner;
use App\Services\PlaybackExpiryResolver;
use Illuminate\Support\Carbon;
use RuntimeException;

class BunnyStreamVideoProvider implements VideoProviderInterface
{
    public function __construct(
        protected PlaybackExpiryResolver $expiryResolver,
        protected BunnyCdnTokenSigner $tokenSigner,
    ) {}

    public function supports(Video $video): bool
    {
        return $video->storage_provider === 'bunny';
    }

    /**
     * @return array{url: string, expires_at: Carbon}
     */
    public function generateSignedPlaybackUrl(Video $video, User $user): array
    {
        $videoId = $video->external_video_id;

        if ($videoId === null || $videoId === '') {
            throw new RuntimeException('Bunny video id is not configured.');
        }

        $tokenKey = (string) config('video.bunny.token_key');
        $cdnHostname = rtrim((string) config('video.bunny.cdn_hostname'), '/');

        if ($tokenKey === '' || $cdnHostname === '') {
            throw new RuntimeException('Bunny Stream CDN token credentials are not configured.');
        }

        $expiresAt = $this->expiryResolver->resolve($user, $video);
        $playlistPath = '/'.$videoId.'/playlist.m3u8';
        $directoryPath = '/'.$videoId.'/';
        $baseUrl = 'https://'.$cdnHostname.$playlistPath;

        $userIp = config('video.bunny.token_ip_binding') ? (request()->ip() ?? '') : '';

        $signedUrl = $this->tokenSigner->signUrl(
            url: $baseUrl,
            securityKey: $tokenKey,
            expiresAt: $expiresAt->getTimestamp(),
            isDirectory: true,
            pathAllowed: $directoryPath,
            userIp: is_string($userIp) ? $userIp : '',
        );

        return [
            'url' => $signedUrl,
            'expires_at' => $expiresAt,
        ];
    }

    public function isConfigured(): bool
    {
        return filled(config('video.bunny.token_key'))
            && filled(config('video.bunny.cdn_hostname'));
    }
}
