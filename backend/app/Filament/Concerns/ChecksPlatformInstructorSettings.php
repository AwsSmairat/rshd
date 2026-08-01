<?php

namespace App\Filament\Concerns;

use App\Services\PlatformSettingsService;

trait ChecksPlatformInstructorSettings
{
    protected static function platformSettings(): PlatformSettingsService
    {
        return app(PlatformSettingsService::class);
    }

    protected static function instructorMay(string $key): bool
    {
        $user = auth()->user();

        if ($user?->isAdmin()) {
            return true;
        }

        if (! $user?->isInstructor()) {
            return false;
        }

        return static::platformSettings()->enabled($key, 'instructors');
    }
}
