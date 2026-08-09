<?php

namespace App\Support;

use Illuminate\Support\Facades\Log;

class SafeLogger
{
    /**
     * @param  array<string, mixed>  $context
     */
    public static function warning(string $message, array $context = []): void
    {
        Log::warning($message, SensitiveDataRedactor::redactContext($context));
    }

    /**
     * @param  array<string, mixed>  $context
     */
    public static function info(string $message, array $context = []): void
    {
        Log::info($message, SensitiveDataRedactor::redactContext($context));
    }

    /**
     * @param  array<string, mixed>  $context
     */
    public static function error(string $message, array $context = []): void
    {
        Log::error($message, SensitiveDataRedactor::redactContext($context));
    }
}
