<?php

namespace App\Policies;

use App\Models\Quiz;
use App\Models\User;
use App\Policies\Concerns\ChecksSubjectAccess;

class QuizPolicy
{
    use ChecksSubjectAccess;

    public function viewAny(User $user): bool
    {
        return $user->isAdmin() || $user->isInstructor() || $user->isStudent();
    }

    public function view(User $user, Quiz $quiz): bool
    {
        $quiz->loadMissing('subject');

        return $this->canAccessSubject($user, $quiz->subject);
    }

    public function start(User $user, Quiz $quiz): bool
    {
        if (! $user->isStudent()) {
            return false;
        }

        $quiz->loadMissing('subject');

        return $this->canAccessSubject($user, $quiz->subject);
    }

    public function submit(User $user, Quiz $quiz): bool
    {
        return $this->start($user, $quiz);
    }

    public function update(User $user, Quiz $quiz): bool
    {
        $quiz->loadMissing('subject');

        return $this->canManageSubject($user, $quiz->subject);
    }

    public function delete(User $user, Quiz $quiz): bool
    {
        $quiz->loadMissing('subject');

        return $this->canManageSubject($user, $quiz->subject);
    }
}
