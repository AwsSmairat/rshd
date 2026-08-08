<?php

namespace App\Services\Bunny;

use InvalidArgumentException;
use RuntimeException;

/**
 * Signed Pull Zone URLs for lesson files/PDFs (separate from Bunny Stream playback).
 */
class BunnyFilesCdnTokenSigner
{
    public function __construct(
        protected BunnyCdnTokenSigner $signer,
    ) {}

    public function isConfigured(): bool
    {
        return filled(config('files.bunny.cdn_hostname'))
            && filled(config('files.bunny.token_key'));
    }

    /**
     * @throws RuntimeException
     */
    public function signCdnPath(string $cdnPath, ?int $expiresAt = null): string
    {
        if (! $this->isConfigured()) {
            throw new RuntimeException('Bunny Files CDN signing is not configured.');
        }

        $normalizedPath = '/'.ltrim($cdnPath, '/');
        $hostname = rtrim((string) config('files.bunny.cdn_hostname'), '/');
        $url = "https://{$hostname}{$normalizedPath}";

        $expiresAt ??= time() + (int) config('files.download_ttl', 600);

        return $this->signer->signUrl(
            url: $url,
            securityKey: (string) config('files.bunny.token_key'),
            expiresAt: $expiresAt,
        );
    }

    public function unsignedCdnUrl(string $cdnPath): string
    {
        $hostname = rtrim((string) config('files.bunny.cdn_hostname'), '/');
        $normalizedPath = '/'.ltrim($cdnPath, '/');

        return "https://{$hostname}{$normalizedPath}";
    }

    /**
     * @throws InvalidArgumentException
     */
    public function signUrl(
        string $url,
        ?int $expiresAt = null,
    ): string {
        if (! filled(config('files.bunny.token_key'))) {
            throw new RuntimeException('Bunny Files CDN signing is not configured.');
        }

        $expiresAt ??= time() + (int) config('files.download_ttl', 600);

        return $this->signer->signUrl(
            url: $url,
            securityKey: (string) config('files.bunny.token_key'),
            expiresAt: $expiresAt,
        );
    }
}
