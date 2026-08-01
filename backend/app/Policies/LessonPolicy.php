<?php

namespace App\Policies;

use App\Enums\ContentStatus;
use App\Models\Lesson;
use App\Models\User;
use App\Policies\Concerns\ChecksSubjectAccess;

class LessonPolicy
{
    use ChecksSubjectAccess;

    public function viewAny(User $user): bool
    {
        return $user->isAdmin() || $user->isInstructor() || $user->isStudent();
    }

    public function view(User $user, Lesson $lesson): bool
    {
        $lesson->loadMissing('subject');

        if ($this->canAccessSubject($user, $lesson->subject)) {
            return true;
        }

        return $user->isStudent()
            && $lesson->subject?->status === ContentStatus::Active
            && $lesson->status === ContentStatus::Active;
    }

    public function create(User $user): bool
    {
        return $user->isAdmin() || $user->isInstructor();
    }

    public function update(User $user, Lesson $lesson): bool
    {
        $lesson->loadMissing('subject');

        return $this->canManageSubject($user, $lesson->subject);
    }

    public function delete(User $user, Lesson $lesson): bool
    {
        $lesson->loadMissing('subject');

        return $this->canManageSubject($user, $lesson->subject);
    }
}
