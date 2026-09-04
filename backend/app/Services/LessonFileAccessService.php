<?php

namespace App\Services;

use App\Enums\LessonFileStorageStatus;
use App\Enums\UserStatus;
use App\Models\LessonFile;
use App\Models\User;
use App\Services\Bunny\BunnyFilesCdnTokenSigner;

/**
 * Download access for lesson files mirrors video playback priority without free-preview.
 */
class LessonFileAccessService
{
    public function __construct(
        protected EnrollmentService $enrollment,
    ) {}

    public function canDownload(User $user, LessonFile $lessonFile): bool
    {
        if ($user->status === UserStatus::Blocked) {
            return false;
        }

        $lessonFile->loadMissing('lesson.subject');

        if ($user->isAdmin()) {
            return true;
        }

        if ($user->isInstructor()
            && $lessonFile->lesson?->subject?->instructor_id === $user->id) {
            return true;
        }

        if ($user->isStudent() && $lessonFile->lesson?->subject !== null) {
            return $this->enrollment->checkStudentAccessToSubject($user, $lessonFile->lesson->subject);
        }

        return false;
    }

    public function isReadyForDownload(LessonFile $lessonFile): bool
    {
        if ($lessonFile->file_type?->needsPdfPreview()) {
            return filled($lessonFile->file_path);
        }

        if ($lessonFile->isBunnyStored()) {
            if ($lessonFile->storage_status !== LessonFileStorageStatus::Ready) {
                return false;
            }

            if (! filled($lessonFile->external_path)) {
                return false;
            }

            return app(BunnyFilesCdnTokenSigner::class)->isConfigured();
        }

        return filled($lessonFile->file_path) || filled($lessonFile->file_url);
    }
}
