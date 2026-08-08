<?php

namespace App\Services\LessonFiles;

use App\Enums\FileType;
use App\Enums\LessonFileStorageStatus;
use App\Models\LessonFile;
use App\Services\Bunny\BunnyFilesStorageClient;
use Illuminate\Support\Str;

class LessonFileBunnyUploadService
{
    public function __construct(
        protected BunnyFilesStorageClient $storage,
    ) {}

    public function uploadLessonFile(LessonFile $lessonFile): string
    {
        if (! $this->storage->isConfigured()) {
            throw new \RuntimeException('Bunny Files storage is not configured.');
        }

        $sourceDisk = $lessonFile->localSourceDiskName();
        $sourcePath = (string) $lessonFile->file_path;

        if ($sourcePath === '' || ! \Illuminate\Support\Facades\Storage::disk($sourceDisk)->exists($sourcePath)) {
            throw new \RuntimeException('Local source file is missing.');
        }

        $contents = \Illuminate\Support\Facades\Storage::disk($sourceDisk)->get($sourcePath);
        $extension = pathinfo($sourcePath, PATHINFO_EXTENSION) ?: 'pdf';
        $remotePath = 'lesson-files/'.$lessonFile->id.'/'.Str::ulid().'.'.$extension;

        if (! $this->storage->upload($remotePath, $contents, (string) ($lessonFile->file_mime_type ?: 'application/pdf'))) {
            throw new \RuntimeException('Bunny Storage upload failed.');
        }

        if (! $this->storage->exists($remotePath)) {
            throw new \RuntimeException('Uploaded object not found on Bunny Storage.');
        }

        return $remotePath;
    }

    public function markUploading(LessonFile $lessonFile): void
    {
        $lessonFile->forceFill([
            'storage_provider' => 'bunny',
            'storage_disk' => $lessonFile->storage_disk ?: LessonFile::defaultLocalSourceDisk(),
            'storage_status' => LessonFileStorageStatus::Pending,
            'file_url' => '',
        ])->save();
    }

    public function markReady(LessonFile $lessonFile, string $externalPath): void
    {
        $lessonFile->forceFill([
            'storage_provider' => 'bunny',
            'storage_disk' => $lessonFile->storage_disk ?: LessonFile::defaultLocalSourceDisk(),
            'external_path' => $externalPath,
            'storage_status' => LessonFileStorageStatus::Ready,
            'uploaded_at' => now(),
            'file_url' => '',
        ])->save();
    }

    public function markFailed(LessonFile $lessonFile): void
    {
        $lessonFile->forceFill([
            'storage_status' => LessonFileStorageStatus::Failed,
        ])->save();
    }

    public function shouldUploadToBunny(LessonFile $lessonFile): bool
    {
        return $lessonFile->file_type === FileType::Pdf
            && filled($lessonFile->file_path)
            && ! $lessonFile->isBunnyStored();
    }
}
