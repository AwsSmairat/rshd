<?php

namespace App\Console\Commands;

use App\Models\Video;
use App\Services\Bunny\BunnyCdnTokenSigner;
use App\Services\Video\BunnyStreamVideoProvider;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;

class BunnyPlaybackCheckCommand extends Command
{
    protected $signature = 'bunny:playback-check {video? : Local video id (defaults to latest bunny video)}';

    protected $description = 'Diagnose Bunny Stream playback (CDN vs embed) without printing secrets';

    public function handle(BunnyStreamVideoProvider $provider, BunnyCdnTokenSigner $signer): int
    {
        if (config('video.provider') !== 'bunny') {
            $this->error('VIDEO_PROVIDER is not bunny.');

            return self::FAILURE;
        }

        $video = $this->resolveVideo();

        if ($video === null) {
            $this->error('No Bunny video found to test.');

            return self::FAILURE;
        }

        $guid = (string) $video->external_video_id;
        $cdn = rtrim((string) config('video.bunny.cdn_hostname'), '/');
        $libraryId = (string) config('video.bunny.library_id');
        $tokenKey = (string) config('video.bunny.token_key');
        $mode = (string) config('video.bunny.playback_mode', 'embed');

        $this->line('Video #'.$video->id.' status='.$video->status->value.' guid='.$guid);
        $this->line('playback_mode='.$mode);
        $this->line('cdn_hostname='.$cdn);
        $this->line('token_key_configured='.($tokenKey !== '' ? 'yes' : 'no'));
        $this->line('token_key_length='.strlen($tokenKey));

        $unsignedCdn = "https://{$cdn}/{$guid}/playlist.m3u8";
        $signedCdn = $tokenKey !== ''
            ? $signer->signUrl($unsignedCdn, $tokenKey, time() + 3600, true, "/{$guid}/", '')
            : null;
        $embedUrl = "https://iframe.mediadelivery.net/embed/{$libraryId}/{$guid}?autoplay=false";

        $this->newLine();
        $this->info('HTTP probes');
        $this->table(
            ['Target', 'HTTP'],
            [
                ['CDN unsigned HLS', $this->probe($unsignedCdn)],
                ['CDN signed HLS', $signedCdn !== null ? $this->probe($signedCdn) : 'skipped'],
                ['Embed iframe', $this->probe($embedUrl)],
            ],
        );

        $this->newLine();
        $this->line('Recommendations:');

        $cdnStatus = $this->probe($signedCdn ?? $unsignedCdn);

        if ($cdnStatus === '403') {
            $this->warn('- CDN returns 403: Pull Zone security is blocking direct playback.');
            $this->warn('- Stream tokenAuthEnabled=false but CDN still blocks → disable "Block Direct URL File Access" on the linked Pull Zone.');
            $this->warn('- Or enable Pull Zone Token Authentication and set the correct BUNNY_STREAM_TOKEN_KEY.');
            $this->warn('- Until CDN works, keep BUNNY_STREAM_LOCAL_FALLBACK=true to play staged local files.');
        }

        if ($this->probe($embedUrl) === '200' && $cdnStatus === '403') {
            $this->info('- Embed playback works. Set BUNNY_STREAM_PLAYBACK_MODE=embed (default) for mobile apps.');
        }

        if ($mode === 'cdn' && $cdnStatus !== '200') {
            $this->error('playback_mode=cdn but CDN is not reachable.');

            return self::FAILURE;
        }

        if ($mode === 'embed' && $this->probe($embedUrl) !== '200') {
            $this->error('playback_mode=embed but embed iframe is not reachable.');

            return self::FAILURE;
        }

        $this->info('Playback check completed.');

        return self::SUCCESS;
    }

    protected function resolveVideo(): ?Video
    {
        $id = $this->argument('video');

        if ($id !== null) {
            return Video::query()
                ->whereKey($id)
                ->where('storage_provider', 'bunny')
                ->first();
        }

        return Video::query()
            ->where('storage_provider', 'bunny')
            ->whereNotNull('external_video_id')
            ->latest('id')
            ->first();
    }

    protected function probe(string $url): string
    {
        try {
            $response = Http::timeout(20)->get($url);

            return (string) $response->status();
        } catch (\Throwable) {
            return 'error';
        }
    }
}
