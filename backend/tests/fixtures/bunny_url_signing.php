<?php

/**
 * Official Bunny CDN url_signing.php (BunnyWay/BunnyCDN.TokenAuthentication).
 * Used only to validate BunnyCdnTokenSigner parity in unit tests.
 */

function sign_bcdn_url(
    string $url,
    string $security_key,
    int $expiration_time = 86400,
    string $user_ip = '',
    bool $is_directory = false,
    string $path_allowed = '',
    string $countries_allowed = '',
    string $countries_blocked = '',
    bool $ignore_params = false,
    ?int $expires_at = null,
    int $speed_limit = 0
): string {
    if ($security_key === '') {
        throw new InvalidArgumentException('security_key must not be empty');
    }
    if ($expiration_time < 0) {
        throw new InvalidArgumentException('expiration_time must be non-negative');
    }

    $parsed = parse_url($url);
    $url_scheme = $parsed['scheme'] ?? '';
    $url_host = $parsed['host'] ?? '';
    $url_path = $parsed['path'] ?? '/';
    $url_query = $parsed['query'] ?? '';

    $query_params = [];
    if ($url_query !== '') {
        foreach (explode('&', $url_query) as $pair) {
            $parts = explode('=', $pair, 2);
            $key = rawurldecode($parts[0]);
            $value = isset($parts[1]) ? rawurldecode($parts[1]) : '';
            if (array_key_exists($key, $query_params)) {
                throw new InvalidArgumentException("Duplicate query parameter '{$key}' is not supported");
            }
            $query_params[$key] = $value;
        }
    }

    if ($countries_allowed !== '') {
        $query_params['token_countries'] = $countries_allowed;
    }
    if ($countries_blocked !== '') {
        $query_params['token_countries_blocked'] = $countries_blocked;
    }
    if ($speed_limit > 0) {
        $query_params['limit'] = (string) $speed_limit;
    }

    $expires = $expires_at !== null ? $expires_at : time() + $expiration_time;

    if ($ignore_params) {
        $parameters = ['token_ignore_params' => 'true'];
    } else {
        $parameters = $query_params;
    }

    if ($path_allowed !== '') {
        $parameters['token_path'] = $path_allowed;
    }

    ksort($parameters);

    $signature_path = $path_allowed !== '' ? $path_allowed : $url_path;

    $signing_parts = [];
    $url_parts = [];
    foreach ($parameters as $key => $value) {
        $signing_parts[] = "{$key}={$value}";
        $url_parts[] = "{$key}=".rawurlencode($value);
    }
    $signing_data = implode('&', $signing_parts);
    $url_data = implode('&', $url_parts);

    $has_ip = $user_ip !== '';
    $ip_bytes = $has_ip ? user_ip_to_bytes($user_ip) : '';
    $flags_prefix = $has_ip ? '1-' : '';

    $message = $signature_path.$expires.$ip_bytes.$signing_data;
    $digest = hash_hmac('sha256', $message, $security_key, true);

    $token = 'HS256-'.$flags_prefix.rtrim(strtr(base64_encode($digest), '+/', '-_'), '=');

    $base = "{$url_scheme}://{$url_host}";
    $tail = $url_data !== '' ? "&{$url_data}" : '';

    if ($is_directory) {
        return "{$base}/bcdn_token={$token}{$tail}&expires={$expires}{$url_path}";
    }

    return "{$base}{$url_path}?token={$token}{$tail}&expires={$expires}";
}

function user_ip_to_bytes(string $user_ip): string
{
    $bytes = @inet_pton($user_ip);
    if ($bytes === false) {
        throw new InvalidArgumentException("user_ip '{$user_ip}' is not a valid IP address");
    }
    if (strlen($bytes) === 16) {
        $bytes = substr($bytes, 0, 8).str_repeat("\0", 8);
    }

    return $bytes;
}
