<?php

namespace App\Console\Commands;

use App\Enums\FileType;
use App\Enums\LessonFileStorageStatus;
use App\Models\LessonFile;
use App\Services\Bunny\BunnyFilesStorageClient;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

class PilotBunnyFileUploadCommand extends Command
{
    protected $signature = 'files:pilot-bunny-upload
        {--file-id= : Existing lesson file id to attach the pilot upload to}
        {--local-path=lesson-files/01KZ4AS1HE9WER6QGV8NFEZN5B.pdf : Relative path under storage/app/public}';

    protected $description = 'Upload a single pilot PDF to Bunny Storage without deleting local source';

    public function handle(BunnyFilesStorageClient $storage): int
    {
        if (! $storage->isConfigured()) {
            $this->error('Bunny Files storage is not configured.');

            return self::FAILURE;
        }

        $relativeLocalPath = ltrim((string) $this->option('local-path'), '/');
        $absoluteLocalPath = storage_path('app/public/'.$relativeLocalPath);

        if (! File::isFile($absoluteLocalPath)) {
            $this->error("Local pilot PDF not found at storage/app/public/{$relativeLocalPath}");

            return self::FAILURE;
        }

        $mime = File::mimeType($absoluteLocalPath) ?: 'application/pdf';
        if ($mime !== 'application/pdf') {
            $this->error('Local pilot file is not a PDF.');

            return self::FAILURE;
        }

        $lessonFile = $this->resolveLessonFile();

        if ($lessonFile === null) {
            return self::FAILURE;
        }

        $objectName = Str::ulid().'.pdf';
        $remotePath = "lesson-files/{$lessonFile->id}/{$objectName}";
        $contents = File::get($absoluteLocalPath);

        $this->line("Uploading pilot PDF for lesson file #{$lessonFile->id}...");

        if (! $storage->upload($remotePath, $contents, 'application/pdf')) {
            $this->error('Bunny Storage upload failed.');

            return self::FAILURE;
        }

        if (! $storage->exists($remotePath)) {
            $this->error('Uploaded object not found on Bunny Storage.');

            return self::FAILURE;
        }

        $lessonFile->forceFill([
            'file_path' => $lessonFile->file_path ?: $relativeLocalPath,
            'original_file_name' => $lessonFile->original_file_name ?: basename($relativeLocalPath),
            'file_size' => $lessonFile->file_size ?: strlen($contents),
            'file_mime_type' => 'application/pdf',
            'file_type' => FileType::Pdf,
            'file_url' => '',
            'storage_provider' => 'bunny',
            'storage_disk' => config('files.bunny.storage_zone'),
            'external_path' => $remotePath,
            'storage_status' => LessonFileStorageStatus::Ready,
            'uploaded_at' => now(),
        ])->save();

        $this->info('Pilot Bunny upload complete.');
        $this->line('Pilot file ID: '.$lessonFile->id);
        $this->line('External path: '.$remotePath);
        $this->line('Local source preserved: '.$relativeLocalPath);

        return self::SUCCESS;
    }

    protected function resolveLessonFile(): ?LessonFile
    {
        $fileId = $this->option('file-id');

        if ($fileId !== null && $fileId !== '') {
            $lessonFile = LessonFile::query()->find($fileId);

            if ($lessonFile === null) {
                $this->error("Lesson file #{$fileId} not found.");

                return null;
            }

            return $lessonFile;
        }

        $lessonFile = LessonFile::query()->where('file_type', FileType::Pdf)->orderBy('id')->first();

        if ($lessonFile === null) {
            $this->error('No lesson file record available for pilot upload.');

            return null;
        }

        return $lessonFile;
    }
}
