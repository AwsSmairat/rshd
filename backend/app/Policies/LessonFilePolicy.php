<?php

namespace App\Policies;

use App\Models\LessonFile;
use App\Models\User;
use App\Policies\Concerns\ChecksSubjectAccess;
use App\Services\PlatformSettingsService;

class LessonFilePolicy
{
    use ChecksSubjectAccess;

    public function view(User $user, LessonFile $lessonFile): bool
    {
        $lessonFile->loadMissing('lesson.subject');

        return $this->canAccessSubject($user, $lessonFile->lesson->subject);
    }

    public function annotate(User $user, LessonFile $lessonFile): bool
    {
        if (! app(PlatformSettingsService::class)->enabled('allow_pdf_annotations', 'students')) {
            return false;
        }

        if (! $user->isStudent()) {
            return $user->isAdmin();
        }

        $lessonFile->loadMissing('lesson.subject');

        return $this->canAccessSubject($user, $lessonFile->lesson->subject);
    }

    public function update(User $user, LessonFile $lessonFile): bool
    {
        $lessonFile->loadMissing('lesson.subject');

        return $this->canManageSubject($user, $lessonFile->lesson->subject);
    }

    public function delete(User $user, LessonFile $lessonFile): bool
    {
        $lessonFile->loadMissing('lesson.subject');

        return $this->canManageSubject($user, $lessonFile->lesson->subject);
    }
}
