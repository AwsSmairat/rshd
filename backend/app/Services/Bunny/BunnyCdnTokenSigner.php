<?php

namespace App\Services\Bunny;

use InvalidArgumentException;

/**
 * Advanced CDN token authentication (HMAC-SHA256) per Bunny official spec.
 *
 * Ported from BunnyWay/BunnyCDN.TokenAuthentication php/url_signing.php
 *
 * @see https://bunny.net/docs/cdn/security/token-authentication/advanced
 */
class BunnyCdnTokenSigner
{
    /**
     * @throws InvalidArgumentException
     */
    public function signUrl(
        string $url,
        string $securityKey,
        int $expiresAt,
        bool $isDirectory = false,
        string $pathAllowed = '',
        string $userIp = '',
        string $countriesAllowed = '',
        string $countriesBlocked = '',
        bool $ignoreParams = false,
        int $speedLimit = 0,
    ): string {
        if ($securityKey === '') {
            throw new InvalidArgumentException('security_key must not be empty');
        }

        if ($expiresAt < 0) {
            throw new InvalidArgumentException('expires_at must be non-negative');
        }

        $parsed = parse_url($url);

        if ($parsed === false || ! isset($parsed['scheme'], $parsed['host'])) {
            throw new InvalidArgumentException('Invalid URL for Bunny CDN signing.');
        }

        $urlScheme = $parsed['scheme'];
        $urlHost = $parsed['host'];
        $urlPath = $parsed['path'] ?? '/';
        $urlQuery = $parsed['query'] ?? '';

        $queryParams = $this->parseQueryParams($urlQuery);

        if ($countriesAllowed !== '') {
            if (array_key_exists('token_countries', $queryParams)) {
                throw new InvalidArgumentException("Duplicate query parameter 'token_countries' is not supported");
            }

            $queryParams['token_countries'] = $countriesAllowed;
        }

        if ($countriesBlocked !== '') {
            if (array_key_exists('token_countries_blocked', $queryParams)) {
                throw new InvalidArgumentException("Duplicate query parameter 'token_countries_blocked' is not supported");
            }

            $queryParams['token_countries_blocked'] = $countriesBlocked;
        }

        if ($speedLimit > 0) {
            $queryParams['limit'] = (string) $speedLimit;
        }

        $expires = $expiresAt;

        if ($ignoreParams) {
            $parameters = ['token_ignore_params' => 'true'];
        } else {
            $parameters = $queryParams;
        }

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

        $message = $signaturePath.$expires.$ipBytes.$signingData;
        $digest = hash_hmac('sha256', $message, $securityKey, true);
        $token = 'HS256-'.$flagsPrefix.rtrim(strtr(base64_encode($digest), '+/', '-_'), '=');

        $base = "{$urlScheme}://{$urlHost}";
        $tail = $urlData !== '' ? "&{$urlData}" : '';

        if ($isDirectory) {
            return "{$base}/bcdn_token={$token}{$tail}&expires={$expires}{$urlPath}";
        }

        return "{$base}{$urlPath}?token={$token}{$tail}&expires={$expires}";
    }

    /**
     * @return array<string, string>
     */
    protected function parseQueryParams(string $urlQuery): array
    {
        if ($urlQuery === '') {
            return [];
        }

        $queryParams = [];

        foreach (explode('&', $urlQuery) as $pair) {
            $parts = explode('=', $pair, 2);
            $key = rawurldecode($parts[0]);
            $value = isset($parts[1]) ? rawurldecode($parts[1]) : '';

            if (array_key_exists($key, $queryParams)) {
                throw new InvalidArgumentException("Duplicate query parameter '{$key}' is not supported");
            }

            $queryParams[$key] = $value;
        }

        return $queryParams;
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
