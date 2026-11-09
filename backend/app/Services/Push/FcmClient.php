<?php

namespace App\Services\Push;

use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * A minimal Firebase Cloud Messaging HTTP v1 client.
 *
 * It signs a service-account JWT itself (RS256 through openssl) and trades it
 * for a short-lived OAuth access token, cached until shortly before it
 * expires. The service account never leaves the server.
 */
class FcmClient
{
    private const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

    private const TOKEN_URI = 'https://oauth2.googleapis.com/token';

    private const CACHE_KEY = 'fcm:access_token';

    /** @var array<string, mixed>|null */
    private ?array $credentials = null;

    public function isConfigured(): bool
    {
        try {
            $this->credentials();

            return true;
        } catch (RuntimeException) {
            return false;
        }
    }

    public function projectId(): string
    {
        $configured = trim((string) config('services.firebase.project_id'));

        return $configured !== '' ? $configured : (string) ($this->credentials()['project_id'] ?? '');
    }

    /**
     * Sends one message (the body of `{"message": …}`) to one token.
     */
    public function send(array $message): FcmSendResult
    {
        $response = $this->post($message, $this->accessToken());

        if ($response->status() === 401) {
            // The cached access token was revoked or expired early.
            Cache::forget(self::CACHE_KEY);
            $response = $this->post($message, $this->accessToken());
        }

        return FcmSendResult::fromResponse($response->status(), $response->json() ?? []);
    }

    private function post(array $message, string $accessToken): Response
    {
        return Http::withToken($accessToken)
            ->acceptJson()
            ->timeout(10)
            ->post(
                'https://fcm.googleapis.com/v1/projects/'.rawurlencode($this->projectId()).'/messages:send',
                ['message' => $message],
            );
    }

    private function accessToken(): string
    {
        $cached = Cache::get(self::CACHE_KEY);
        if (is_string($cached) && $cached !== '') {
            return $cached;
        }

        $credentials = $this->credentials();
        $now = time();
        $jwt = $this->signJwt([
            'iss' => $credentials['client_email'],
            'scope' => self::SCOPE,
            'aud' => $credentials['token_uri'] ?? self::TOKEN_URI,
            'iat' => $now,
            'exp' => $now + 3600,
        ], (string) $credentials['private_key']);

        $response = Http::asForm()
            ->timeout(10)
            ->post($credentials['token_uri'] ?? self::TOKEN_URI, [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt,
            ]);

        $token = $response->json('access_token');
        if (! $response->successful() || ! is_string($token) || $token === '') {
            throw new RuntimeException('Firebase access token request failed with status '.$response->status().'.');
        }

        $ttl = max(60, (int) $response->json('expires_in', 3600) - 300);
        Cache::put(self::CACHE_KEY, $token, $ttl);

        return $token;
    }

    /**
     * @param  array<string, mixed>  $claims
     */
    private function signJwt(array $claims, string $privateKey): string
    {
        $segments = [
            $this->base64Url(json_encode(['alg' => 'RS256', 'typ' => 'JWT'], JSON_THROW_ON_ERROR)),
            $this->base64Url(json_encode($claims, JSON_THROW_ON_ERROR)),
        ];

        $key = openssl_pkey_get_private($privateKey);
        if ($key === false) {
            throw new RuntimeException('The Firebase service account private key is not valid.');
        }

        $signature = '';
        if (! openssl_sign(implode('.', $segments), $signature, $key, OPENSSL_ALGO_SHA256)) {
            throw new RuntimeException('Signing the Firebase token failed.');
        }

        $segments[] = $this->base64Url($signature);

        return implode('.', $segments);
    }

    private function base64Url(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }

    /**
     * @return array<string, mixed>
     */
    private function credentials(): array
    {
        if ($this->credentials !== null) {
            return $this->credentials;
        }

        $raw = trim((string) config('services.firebase.credentials_json'));

        if ($raw !== '' && ! str_starts_with($raw, '{')) {
            $decoded = base64_decode($raw, true);
            $raw = $decoded === false ? $raw : trim($decoded);
        }

        if ($raw === '') {
            $path = (string) config('services.firebase.credentials');
            if ($path === '' || ! is_file($path) || ! is_readable($path)) {
                throw new RuntimeException('Firebase credentials are not configured.');
            }
            $raw = (string) file_get_contents($path);
        }

        $credentials = json_decode($raw, true);
        if (! is_array($credentials)
            || ($credentials['type'] ?? null) !== 'service_account'
            || empty($credentials['client_email'])
            || empty($credentials['private_key'])) {
            throw new RuntimeException('Firebase credentials are not a valid service account.');
        }

        return $this->credentials = $credentials;
    }
}
