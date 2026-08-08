<?php

namespace App\Console\Commands;

use App\Services\Bunny\BunnyFilesStorageClient;
use App\Services\LessonFiles\LessonFileBunnyStorageAuditService;
use Illuminate\Console\Command;

class DeleteBunnyLessonFileOrphanCommand extends Command
{
    protected $signature = 'files:delete-bunny-orphan
                            {--path= : Exact Bunny object path, e.g. lesson-files/1/file.pdf}
                            {--confirm : Required to perform deletion}';

    protected $description = 'Delete a single confirmed Bunny orphan object (exact path only, no wildcards)';

    public function handle(
        LessonFileBunnyStorageAuditService $auditService,
        BunnyFilesStorageClient $storage,
    ): int {
        $path = trim((string) $this->option('path'));

        if ($path === '' || str_contains($path, '*') || str_contains($path, '?')) {
            $this->error('Provide an exact --path without wildcards.');

            return self::FAILURE;
        }

        if (! preg_match('#^lesson-files/\d+/[^/]+\.pdf$#i', $path)) {
            $this->error('Path must match lesson-files/{id}/{filename}.pdf');

            return self::FAILURE;
        }

        if (! (bool) $this->option('confirm')) {
            $this->error('Refusing to delete without --confirm.');

            return self::FAILURE;
        }

        if (! $auditService->isConfirmedOrphan($path)) {
            $this->error('Path is not a confirmed Bunny orphan.');

            return self::FAILURE;
        }

        if (! $storage->delete($path)) {
            $this->error('Bunny delete request failed.');

            return self::FAILURE;
        }

        $this->info('Confirmed orphan deleted: '.$path);

        return self::SUCCESS;
    }
}
