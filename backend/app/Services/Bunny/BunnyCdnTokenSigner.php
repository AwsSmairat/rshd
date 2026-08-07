<?php

namespace App\Services\Bunny;

use InvalidArgumentException;

/**
 * Advanced CDN token authentication (HMAC-SHA256) per Bunny official spec.
 *
 * @see https://bunny.net/docs/cdn/security/token-authentication/advanced
 */
class BunnyCdnTokenSigner
{
    public function signUrl(
        string $url,
        string $securityKey,
        int $expiresAt,
        bool $isDirectory = false,
        string $pathAllowed = '',
        string $userIp = '',
    ): string {
        $parsed = parse_url($url);

        if ($parsed === false || ! isset($parsed['scheme'], $parsed['host'])) {
            throw new InvalidArgumentException('Invalid URL for Bunny CDN signing.');
        }

        $urlScheme = $parsed['scheme'];
        $urlHost = $parsed['host'];
        $urlPath = $parsed['path'] ?? '/';

        $parameters = [];

        if ($pathAllowed !== '') {
            $parameters['token_path'] = $pathAllowed;
        }

        ksort($parameters);

        $signaturePath = $pathAllowed !== '' ? $pathAllowed : $urlPath;

        $signingParts = [];
        $urlParts = [];

        foreach ($parameters as $key => $value) {
            $signingParts[] = "{$key}={$value}";
            $urlParts[] = "{$key}=".rawurlencode($value);
        }

        $signingData = implode('&', $signingParts);
        $urlData = implode('&', $urlParts);

        $hasIp = $userIp !== '';
        $ipBytes = $hasIp ? $this->userIpToBytes($userIp) : '';
        $flagsPrefix = $hasIp ? '1-' : '';

        $message = $signaturePath.$expiresAt.$ipBytes.$signingData;
        $digest = hash_hmac('sha256', $message, $securityKey, true);
        $token = 'HS256-'.$flagsPrefix.rtrim(strtr(base64_encode($digest), '+/', '-_'), '=');

        $base = "{$urlScheme}://{$urlHost}";
        $tail = $urlData !== '' ? "&{$urlData}" : '';

        if ($isDirectory) {
            return "{$base}/bcdn_token={$token}{$tail}&expires={$expiresAt}{$urlPath}";
        }

        return "{$base}{$urlPath}?token={$token}{$tail}&expires={$expiresAt}";
    }

    protected function userIpToBytes(string $userIp): string
    {
        $bytes = inet_pton($userIp);

        if ($bytes === false) {
            throw new InvalidArgumentException("Invalid IP address for Bunny token binding: {$userIp}");
        }

        if (strlen($bytes) === 16) {
            $bytes = substr($bytes, 0, 8).str_repeat("\0", 8);
        }

        return $bytes;
    }
}
