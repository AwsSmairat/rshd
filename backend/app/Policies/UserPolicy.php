<?php

namespace App\Policies;

use App\Models\User;

class UserPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isAdmin() || $user->isInstructor();
    }

    public function view(User $user, User $model): bool
    {
        if ($user->isAdmin() || $user->id === $model->id) {
            return true;
        }

        return $user->isInstructor() && $this->teachesStudent($user, $model);
    }

    public function create(User $user): bool
    {
        return $user->isAdmin();
    }

    public function update(User $user, User $model): bool
    {
        if ($user->isAdmin() || $user->id === $model->id) {
            return true;
        }

        return $user->isInstructor() && $this->teachesStudent($user, $model);
    }

    public function delete(User $user, User $model): bool
    {
        return $user->isAdmin();
    }

    public function deleteAny(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Instructor may only access students enrolled in their own subjects.
     */
    protected function teachesStudent(User $instructor, User $student): bool
    {
        if (! $student->isStudent()) {
            return false;
        }

        return $student->enrolledSubjects()
            ->where('subjects.instructor_id', $instructor->id)
            ->exists();
    }
}
