<?php

namespace App\Filament\Concerns;

trait InstructorOnlyPage
{
    public static function canAccess(): bool
    {
        return auth()->user()?->isInstructor() ?? false;
    }

    public static function shouldRegisterNavigation(): bool
    {
        return static::canAccess();
    }
}
