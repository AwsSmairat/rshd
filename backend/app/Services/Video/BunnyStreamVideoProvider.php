<?php

namespace App\Services\Video;

use App\Contracts\VideoProviderInterface;
use App\Models\User;
use App\Models\Video;
use App\Services\Bunny\BunnyCdnTokenSigner;
use App\Services\Bunny\BunnyEmbedTokenSigner;
use App\Services\PlaybackExpiryResolver;
use Illuminate\Support\Carbon;
use RuntimeException;

class BunnyStreamVideoProvider implements VideoProviderInterface
{
    public function __construct(
        protected PlaybackExpiryResolver $expiryResolver,
        protected BunnyCdnTokenSigner $tokenSigner,
        protected BunnyEmbedTokenSigner $embedTokenSigner,
    ) {}

    public function supports(Video $video): bool
    {
        return $video->storage_provider === 'bunny';
    }

    /**
     * @return array{url: string, expires_at: Carbon, type: string}
     */
    public function generateSignedPlaybackUrl(Video $video, User $user): array
    {
        $mode = (string) config('video.bunny.playback_mode', 'embed');

        if ($mode === 'cdn') {
            return $this->generateCdnPlaybackUrl($video, $user);
        }

        return $this->generateEmbedPlaybackUrl($video, $user);
    }

    /**
     * @return array{url: string, expires_at: Carbon, type: string}
     */
    protected function generateEmbedPlaybackUrl(Video $video, User $user): array
    {
        $videoId = $video->external_video_id;
        $libraryId = (string) config('video.bunny.library_id');

        if ($videoId === null || $videoId === '') {
            throw new RuntimeException('Bunny video id is not configured.');
        }

        if ($libraryId === '') {
            throw new RuntimeException('Bunny Stream library id is not configured.');
        }

        $expiresAt = $this->expiryResolver->resolve($user, $video);

        $query = [
            'autoplay' => 'true',
            'responsive' => 'true',
            'preload' => 'true',
        ];

        $embedKey = (string) config('video.bunny.embed_token_key');

        if ($embedKey !== '') {
            $expires = $expiresAt->getTimestamp();
            $query['expires'] = (string) $expires;
            $query['token'] = $this->embedTokenSigner->sign($videoId, $embedKey, $expires);
        }

        $url = 'https://iframe.mediadelivery.net/embed/'.$libraryId.'/'.$videoId.'?'.http_build_query($query);

        return [
            'url' => $url,
            'expires_at' => $expiresAt,
            'type' => 'embed',
        ];
    }

    /**
     * @return array{url: string, expires_at: Carbon, type: string}
     */
    protected function generateCdnPlaybackUrl(Video $video, User $user): array
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
            'type' => 'hls',
        ];
    }

    public function isConfigured(): bool
    {
        if (! filled(config('video.bunny.library_id'))) {
            return false;
        }

        if (config('video.bunny.playback_mode', 'embed') === 'cdn') {
            return filled(config('video.bunny.token_key'))
                && filled(config('video.bunny.cdn_hostname'));
        }

        return true;
    }
}
