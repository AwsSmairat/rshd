<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class LoginThrottleService
{
    public function __construct(
        protected PlatformSettingsService $settings,
    ) {}

    public function tooManyAttempts(string $email): bool
    {
        $maxAttempts = max(1, $this->settings->integer('max_login_attempts', 5, 'security'));

        return $this->attempts($email) >= $maxAttempts;
    }

    public function hit(string $email): void
    {
        $key = $this->cacheKey($email);
        $attempts = (int) Cache::get($key, 0) + 1;
        $lockoutMinutes = max(1, $this->settings->integer('login_lockout_minutes', 15, 'security'));

        Cache::put($key, $attempts, now()->addMinutes($lockoutMinutes));
    }

    public function clear(string $email): void
    {
        Cache::forget($this->cacheKey($email));
    }

    public function secondsUntilAvailable(string $email): int
    {
        $expiresAt = Cache::get($this->cacheKey($email).':timer');

        if ($expiresAt === null) {
            return 0;
        }

        return max(0, (int) $expiresAt - time());
    }

    public function lockoutMinutes(): int
    {
        return max(1, $this->settings->integer('login_lockout_minutes', 15, 'security'));
    }

    protected function attempts(string $email): int
    {
        return (int) Cache::get($this->cacheKey($email), 0);
    }

    protected function cacheKey(string $email): string
    {
        return 'platform_login_attempts:'.Str::lower(trim($email));
    }
}
