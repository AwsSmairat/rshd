<?php

namespace App\Services;

use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use RuntimeException;
use ZipArchive;

class PlatformBackupService
{
    public function __construct(
        protected PlatformSettingsService $settings,
    ) {}

    /**
     * @return array{path: string, filename: string}
     */
    public function runBackup(): array
    {
        $timestamp = now()->format('Y-m-d_H-i-s');
        $directory = storage_path('app/backups');
        File::ensureDirectoryExists($directory);

        $filename = "rshd-backup-{$timestamp}.zip";
        $path = $directory.DIRECTORY_SEPARATOR.$filename;

        $zip = new ZipArchive;
        if ($zip->open($path, ZipArchive::CREATE | ZipArchive::OVERWRITE) !== true) {
            throw new RuntimeException('تعذر إنشاء ملف النسخ الاحتياطي.');
        }

        try {
            if ($this->settings->enabled('include_database', 'backup')) {
                $this->addDatabaseToZip($zip, $timestamp);
            }

            if ($this->settings->enabled('include_uploaded_files', 'backup')) {
                $this->addPublicUploadsToZip($zip);
            }
        } catch (\Throwable $exception) {
            $zip->close();
            File::delete($path);
            $this->recordResult('failed');

            throw $exception;
        }

        $zip->close();
        $this->recordResult('success');
        $this->notifyByEmail($path, $filename);

        return [
            'path' => $path,
            'filename' => $filename,
        ];
    }

    /**
     * @return list<string>
     */
    public function listBackups(): array
    {
        $directory = storage_path('app/backups');
        if (! File::isDirectory($directory)) {
            return [];
        }

        return collect(File::files($directory))
            ->filter(fn ($file) => str_ends_with($file->getFilename(), '.zip'))
            ->sortByDesc(fn ($file) => $file->getMTime())
            ->map(fn ($file) => $file->getFilename())
            ->values()
            ->all();
    }

    public function shouldRunScheduledBackup(): bool
    {
        if (! $this->settings->enabled('auto_backup_enabled', 'backup')) {
            return false;
        }

        $lastRun = $this->settings->stringValue('last_backup_at', '', 'backup');
        if ($lastRun === '') {
            return true;
        }

        $frequency = $this->settings->stringValue('backup_frequency', 'daily', 'backup');
        $last = Carbon::parse($lastRun);

        return match ($frequency) {
            'weekly' => $last->lte(now()->subWeek()),
            default => $last->lte(now()->subDay()),
        };
    }

    protected function addDatabaseToZip(ZipArchive $zip, string $timestamp): void
    {
        $connection = config('database.default');
        $driver = config("database.connections.{$connection}.driver");

        if ($driver === 'sqlite') {
            $databasePath = config("database.connections.{$connection}.database");
            if (is_string($databasePath) && File::exists($databasePath)) {
                $zip->addFile($databasePath, "database/sqlite-{$timestamp}.sqlite");
            }

            return;
        }

        if ($driver === 'mysql') {
            $database = config("database.connections.{$connection}.database");
            $username = config("database.connections.{$connection}.username");
            $password = config("database.connections.{$connection}.password");
            $host = config("database.connections.{$connection}.host");
            $port = config("database.connections.{$connection}.port", 3306);

            $dumpPath = storage_path("app/backups/db-{$timestamp}.sql");
            $command = sprintf(
                'mysqldump --host=%s --port=%s --user=%s --password=%s %s > %s',
                escapeshellarg((string) $host),
                escapeshellarg((string) $port),
                escapeshellarg((string) $username),
                escapeshellarg((string) $password),
                escapeshellarg((string) $database),
                escapeshellarg($dumpPath),
            );

            exec($command, $output, $exitCode);

            if ($exitCode !== 0 || ! File::exists($dumpPath)) {
                throw new RuntimeException('فشل تصدير قاعدة البيانات.');
            }

            $zip->addFile($dumpPath, "database/mysql-{$timestamp}.sql");
            register_shutdown_function(static fn () => File::delete($dumpPath));

            return;
        }

        $tables = DB::connection()->select('SELECT name FROM sqlite_master WHERE type = "table"');
        if ($tables !== []) {
            return;
        }

        throw new RuntimeException('نوع قاعدة البيانات غير مدعوم للنسخ الاحتياطي.');
    }

    protected function addPublicUploadsToZip(ZipArchive $zip): void
    {
        $disk = Storage::disk('public');
        $root = $disk->path('');

        if (! File::isDirectory($root)) {
            return;
        }

        foreach ($disk->allFiles() as $file) {
            $absolute = $disk->path($file);
            if (File::exists($absolute)) {
                $zip->addFile($absolute, 'uploads/'.$file);
            }
        }
    }

    protected function recordResult(string $status): void
    {
        $this->settings->set('last_backup_at', now()->toDateTimeString(), 'backup');
        $this->settings->set('last_backup_status', $status, 'backup');
    }

    protected function notifyByEmail(string $path, string $filename): void
    {
        $email = $this->settings->stringValue('backup_notification_email', '', 'backup');
        if ($email === '') {
            return;
        }

        $this->settings->applyMailPreferences();

        Mail::raw(
            "تم إنشاء نسخة احتياطية جديدة: {$filename}",
            fn ($message) => $message->to($email)->subject('نسخة احتياطية RSHD'),
        );
    }
}
