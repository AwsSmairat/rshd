<?php

namespace App\Console\Commands;

use App\Services\PlatformBackupService;
use Illuminate\Console\Command;

class RunPlatformBackupCommand extends Command
{
    protected $signature = 'platform:backup {--force : Run even when auto backup is disabled}';

    protected $description = 'Create a platform backup archive';

    public function handle(PlatformBackupService $backupService): int
    {
        if (! $this->option('force') && ! $backupService->shouldRunScheduledBackup()) {
            $this->info('Auto backup is disabled or not due yet.');

            return self::SUCCESS;
        }

        try {
            $result = $backupService->runBackup();
            $this->info('Backup created: '.$result['filename']);

            return self::SUCCESS;
        } catch (\Throwable $exception) {
            $this->error($exception->getMessage());

            return self::FAILURE;
        }
    }
}
