<?php

namespace App\Services\Bunny;

use Illuminate\Support\Facades\Log;

class BunnyStreamConfigValidator
{
    public static function warnIfMisconfigured(): void
    {
        if (config('video.provider') !== 'bunny') {
            return;
        }

        $tokenKey = (string) config('video.bunny.token_key');
        $cdnHostname = (string) config('video.bunny.cdn_hostname');

        if ($tokenKey === '' || $cdnHostname === '') {
            return;
        }

        $hostnamePrefix = strtok($cdnHostname, '.');

        if ($hostnamePrefix !== false && hash_equals($tokenKey, $hostnamePrefix)) {
            Log::critical('bunny.stream.token_key_looks_like_hostname', [
                'hint' => 'BUNNY_STREAM_TOKEN_KEY must be the Pull Zone URL Token Authentication Key from CDN → Security, not the CDN hostname prefix.',
            ]);
        }
    }
}
