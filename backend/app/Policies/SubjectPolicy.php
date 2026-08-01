<?php

namespace App\Policies;

use App\Enums\ContentStatus;
use App\Models\Subject;
use App\Models\User;
use App\Policies\Concerns\ChecksSubjectAccess;
use App\Services\PlatformSettingsService;

class SubjectPolicy
{
    use ChecksSubjectAccess;

    public function viewAny(User $user): bool
    {
        return $user->isAdmin() || $user->isInstructor() || $user->isStudent();
    }

    public function view(User $user, Subject $subject): bool
    {
        if ($this->canAccessSubject($user, $subject)) {
            return true;
        }

        // Students may preview active subjects (syllabus + free videos).
        return $user->isStudent() && $subject->status === ContentStatus::Active;
    }

    public function create(User $user): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        return $user->isInstructor()
            && app(PlatformSettingsService::class)->enabled('instructor_can_create_subjects', 'instructors');
    }

    public function update(User $user, Subject $subject): bool
    {
        return $this->canManageSubject($user, $subject);
    }

    public function delete(User $user, Subject $subject): bool
    {
        return $this->canManageSubject($user, $subject);
    }
}
