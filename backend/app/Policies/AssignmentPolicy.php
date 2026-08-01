<?php

namespace App\Policies;

use App\Models\Assignment;
use App\Models\User;
use App\Policies\Concerns\ChecksSubjectAccess;

class AssignmentPolicy
{
    use ChecksSubjectAccess;

    public function viewAny(User $user): bool
    {
        return $user->isAdmin() || $user->isInstructor() || $user->isStudent();
    }

    public function view(User $user, Assignment $assignment): bool
    {
        $assignment->loadMissing('subject');

        return $this->canAccessSubject($user, $assignment->subject);
    }

    public function submit(User $user, Assignment $assignment): bool
    {
        if (! $user->isStudent()) {
            return false;
        }

        $assignment->loadMissing('subject');

        return $this->canAccessSubject($user, $assignment->subject);
    }

    public function update(User $user, Assignment $assignment): bool
    {
        $assignment->loadMissing('subject');

        return $this->canManageSubject($user, $assignment->subject);
    }

    public function delete(User $user, Assignment $assignment): bool
    {
        $assignment->loadMissing('subject');

        return $this->canManageSubject($user, $assignment->subject);
    }
}
