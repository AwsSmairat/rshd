<?php

namespace App\Services;

use App\Enums\ContentStatus;
use App\Enums\UserStatus;
use App\Models\User;
use App\Models\Video;

/**
 * Playback access priority:
 * 1. Blocked users are always denied.
 * 2. Admins may preview any video.
 * 3. Subject instructors may preview their own subject videos only.
 * 4. Free preview videos on active subjects (is_free) without enrollment.
 * 5. Enrolled students with paid, active, non-expired access.
 */
class VideoAccessService
{
    public function __construct(
        protected EnrollmentService $enrollment,
    ) {}

    public function canPlay(User $user, Video $video): bool
    {
        if ($user->status === UserStatus::Blocked) {
            return false;
        }

        $video->loadMissing('lesson.subject');

        if ($user->isAdmin()) {
            return true;
        }

        if ($user->isInstructor()
            && $video->lesson?->subject?->instructor_id === $user->id) {
            return true;
        }

        if ((bool) $video->is_free
            && $video->lesson?->subject?->status === ContentStatus::Active) {
            return true;
        }

        if ($user->isStudent() && $video->lesson?->subject !== null) {
            return $this->enrollment->checkStudentAccessToSubject($user, $video->lesson->subject);
        }

        return false;
    }
}
