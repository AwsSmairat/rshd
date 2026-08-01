<?php

namespace App\Policies\Concerns;

use App\Models\Subject;
use App\Models\User;
use App\Services\EnrollmentService;
use App\Services\PlatformSettingsService;

trait ChecksSubjectAccess
{
    protected function canAccessSubject(User $user, Subject $subject): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        if ($user->isInstructor()) {
            return $subject->instructor_id === $user->id;
        }

        if ($user->isStudent()) {
            return app(EnrollmentService::class)->checkStudentAccessToSubject($user, $subject);
        }

        return false;
    }

    protected function canManageSubject(User $user, Subject $subject): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        if (! $user->isInstructor()) {
            return false;
        }

        $settings = app(PlatformSettingsService::class);

        if (! $settings->enabled('instructor_edit_own_only', 'instructors')) {
            return true;
        }

        return $subject->instructor_id === $user->id;
    }
}
