<?php

namespace App\Policies;

use App\Enums\ContentStatus;
use App\Enums\UserStatus;
use App\Models\User;
use App\Models\Video;
use App\Policies\Concerns\ChecksSubjectAccess;

class VideoPolicy
{
    use ChecksSubjectAccess;

    public function view(User $user, Video $video): bool
    {
        if ($user->status === UserStatus::Blocked) {
            return false;
        }

        $video->loadMissing('lesson.subject');

        if ($this->canAccessSubject($user, $video->lesson->subject)) {
            return true;
        }

        // Free preview videos are watchable without enrollment.
        return $user->isStudent()
            && (bool) $video->is_free
            && $video->lesson?->subject?->status === ContentStatus::Active;
    }

    public function updateProgress(User $user, Video $video): bool
    {
        if (! $user->isStudent()) {
            return $user->isAdmin();
        }

        return $this->view($user, $video);
    }

    public function update(User $user, Video $video): bool
    {
        $video->loadMissing('lesson.subject');

        return $this->canManageSubject($user, $video->lesson->subject);
    }

    public function delete(User $user, Video $video): bool
    {
        $video->loadMissing('lesson.subject');

        return $this->canManageSubject($user, $video->lesson->subject);
    }
}
