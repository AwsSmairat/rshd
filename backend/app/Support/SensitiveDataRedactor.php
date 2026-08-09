<?php

namespace App\Support;

class SensitiveDataRedactor
{
    /**
     * @var list<string>
     */
    private const SENSITIVE_KEYS = [
        'authorization',
        'password',
        'secret',
        'token',
        'accesskey',
        'access_key',
        'api_key',
        'api-key',
        'signature',
        'cookie',
        'otp',
        'bearer',
        'refresh_token',
        'storage_password',
    ];

    public static function redactString(?string $value): ?string
    {
        if ($value === null || $value === '') {
            return $value;
        }

        $redacted = $value;

        if (preg_match('/\bBearer\s+\S+/i', $redacted) === 1) {
            $redacted = preg_replace('/\bBearer\s+\S+/i', 'Bearer [REDACTED]', $redacted) ?? $redacted;
        }

        foreach (self::SENSITIVE_KEYS as $key) {
            $pattern = '/('.preg_quote($key, '/').'\s*[=:]\s*)([^\s&"\']+)/i';
            $redacted = preg_replace($pattern, '$1[REDACTED]', $redacted) ?? $redacted;
        }

        if (preg_match('/[?&](token|signature|expires|accesskey|access_key)=/i', $redacted) === 1) {
            $redacted = preg_replace(
                '/([?&](?:token|signature|expires|accesskey|access_key)=)[^&\s"\']+/i',
                '$1[REDACTED]',
                $redacted,
            ) ?? $redacted;
        }

        return $redacted;
    }

    /**
     * @param  array<string, mixed>  $context
     * @return array<string, mixed>
     */
    public static function redactContext(array $context): array
    {
        $output = [];

        foreach ($context as $key => $value) {
            if (self::isSensitiveKey((string) $key)) {
                $output[$key] = '[REDACTED]';

                continue;
            }

            if (is_string($value)) {
                $output[$key] = self::redactString($value);

                continue;
            }

            if (is_array($value)) {
                $output[$key] = self::redactContext($value);

                continue;
            }

            $output[$key] = $value;
        }

        return $output;
    }

    public static function isSensitiveKey(string $key): bool
    {
        $normalized = strtolower($key);

        foreach (self::SENSITIVE_KEYS as $sensitive) {
            if (str_contains($normalized, $sensitive)) {
                return true;
            }
        }

        return false;
    }
}
