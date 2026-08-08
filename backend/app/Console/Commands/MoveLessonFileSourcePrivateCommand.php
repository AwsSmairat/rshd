<?php

namespace App\Console\Commands;

use App\Models\LessonFile;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

class MoveLessonFileSourcePrivateCommand extends Command
{
    protected $signature = 'files:move-local-source-private
                            {--file-id= : Lesson file id to move}
                            {--apply : Perform the move (default is dry-run)}';

    protected $description = 'Move a lesson file local source from public disk to private lesson_files disk with checksum verification';

    public function handle(): int
    {
        $fileId = (int) $this->option('file-id');

        if ($fileId <= 0) {
            $this->error('Provide --file-id');

            return self::FAILURE;
        }

        $lessonFile = LessonFile::query()->find($fileId);

        if ($lessonFile === null) {
            $this->error("Lesson file #{$fileId} not found.");

            return self::FAILURE;
        }

        $sourcePath = (string) $lessonFile->file_path;

        if ($sourcePath === '') {
            $this->error('Lesson file has no local source path.');

            return self::FAILURE;
        }

        if (! Storage::disk('public')->exists($sourcePath)) {
            $privateDisk = Storage::disk(LessonFile::defaultLocalSourceDisk());
            if ($privateDisk->exists($sourcePath)) {
                $this->info('Local source already on private disk.');

                return self::SUCCESS;
            }

            $this->error('Public source file not found.');

            return self::FAILURE;
        }

        $publicBytes = Storage::disk('public')->get($sourcePath);
        $checksumBefore = hash('sha256', $publicBytes);
        $targetPath = 'sources/'.$lessonFile->id.'/'.basename($sourcePath);

        $this->line("Source: public://{$sourcePath}");
        $this->line("Target: lesson_files://{$targetPath}");
        $this->line('Checksum before: '.substr($checksumBefore, 0, 16).'…');

        if (! (bool) $this->option('apply')) {
            $this->warn('Dry run only. Re-run with --apply to move.');

            return self::SUCCESS;
        }

        $privateDisk = Storage::disk(LessonFile::defaultLocalSourceDisk());
        $privateDisk->put($targetPath, $publicBytes);

        $privateBytes = $privateDisk->get($targetPath);
        $checksumAfter = hash('sha256', $privateBytes);

        if ($checksumBefore !== $checksumAfter) {
            $privateDisk->delete($targetPath);
            $this->error('Checksum mismatch after copy. Public source preserved.');

            return self::FAILURE;
        }

        Storage::disk('public')->delete($sourcePath);

        $lessonFile->forceFill([
            'file_path' => $targetPath,
            'storage_disk' => LessonFile::defaultLocalSourceDisk(),
        ])->save();

        $this->info('Local source moved to private disk.');
        $this->line('Checksum verified: PASS');

        return self::SUCCESS;
    }
}
