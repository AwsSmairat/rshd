<?php

namespace App\Policies;

use App\Models\Grade;
use App\Models\User;
use App\Policies\Concerns\ChecksSubjectAccess;

class GradePolicy
{
    use ChecksSubjectAccess;

    public function viewAny(User $user): bool
    {
        return $user->isAdmin() || $user->isInstructor() || $user->isStudent();
    }

    public function view(User $user, Grade $grade): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        if ($user->isStudent()) {
            return $grade->student_id === $user->id;
        }

        if ($user->isInstructor()) {
            $grade->loadMissing('subject');

            return $grade->subject->instructor_id === $user->id;
        }

        return false;
    }
}
