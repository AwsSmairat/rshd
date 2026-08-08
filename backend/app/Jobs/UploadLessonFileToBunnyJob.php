<?php

namespace App\Jobs;

use App\Models\LessonFile;
use App\Services\LessonFiles\LessonFileBunnyUploadService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;
use Throwable;

class UploadLessonFileToBunnyJob implements ShouldQueue
{
    use Queueable;

    public int $tries = 3;

    public int $timeout = 1200;

    /**
     * @return array<int, int>
     */
    public function backoff(): array
    {
        return [15, 60, 180];
    }

    public function __construct(public int $lessonFileId) {}

    public function handle(LessonFileBunnyUploadService $uploadService): void
    {
        $lessonFile = LessonFile::query()->find($this->lessonFileId);

        if ($lessonFile === null) {
            return;
        }

        if ($lessonFile->isBunnyStored()) {
            return;
        }

        if (! $uploadService->shouldUploadToBunny($lessonFile)) {
            return;
        }

        $uploadService->markUploading($lessonFile);

        try {
            $externalPath = $uploadService->uploadLessonFile($lessonFile);
            $uploadService->markReady($lessonFile, $externalPath);
        } catch (Throwable $exception) {
            $uploadService->markFailed($lessonFile);

            Log::warning('bunny.files.upload.failed', [
                'file_id' => $lessonFile->id,
                'reason' => $exception->getMessage(),
            ]);

            throw $exception;
        }
    }
}
