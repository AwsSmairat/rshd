<?php

namespace App\Services\Bunny;

/**
 * Embed view token authentication for Bunny Stream iframes.
 *
 * @see https://docs.bunny.net/docs/stream-embed-token-authentication
 */
class BunnyEmbedTokenSigner
{
    public function sign(string $videoGuid, string $securityKey, int $expiresAt): string
    {
        return hash('sha256', $securityKey.$videoGuid.$expiresAt);
    }
}
