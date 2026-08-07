<?php

namespace App\Console\Commands;

use App\Models\Video;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

class MigrateVideosToPrivateCommand extends Command
{
    protected $signature = 'videos:migrate-to-private
                            {--dry-run : Preview actions without copying or deleting files}
                            {--remove-source : Delete public copies after successful verification}';

    protected $description = 'Migrate lesson video files from public storage to the private lesson_videos disk';

    public function handle(): int
    {
        $dryRun = (bool) $this->option('dry-run');
        $removeSource = (bool) $this->option('remove-source');

        if ($removeSource && $dryRun) {
            $this->warn('--remove-source ignored during dry-run.');

            $removeSource = false;
        }

        $publicDisk = Storage::disk('public');
        $privateDisk = Storage::disk('lesson_videos');

        $videos = Video::query()
            ->whereNotNull('video_path')
            ->where('video_path', '!=', '')
            ->orderBy('id')
            ->get();

        if ($videos->isEmpty()) {
            $this->info('No videos with local paths were found.');

            return self::SUCCESS;
        }

        $copied = 0;
        $skipped = 0;
        $missing = 0;
        $failed = 0;
        $removed = 0;

        foreach ($videos as $video) {
            $path = $video->video_path;

            if ($privateDisk->exists($path) && $this->filesMatch($publicDisk, $privateDisk, $path)) {
                $this->line("SKIP video #{$video->id}: already on private disk ({$path})");
                $skipped++;

                if ($removeSource && $publicDisk->exists($path)) {
                    if ($dryRun) {
                        continue;
                    }

                    $publicDisk->delete($path);
                    $removed++;
                    $this->line("  removed public copy: {$path}");
                }

                continue;
            }

            if (! $publicDisk->exists($path)) {
                if ($privateDisk->exists($path)) {
                    $this->line("SKIP video #{$video->id}: only private copy exists ({$path})");
                    $skipped++;

                    continue;
                }

                $this->warn("MISSING video #{$video->id}: {$path}");
                $missing++;

                continue;
            }

            if ($dryRun) {
                $this->line("DRY-RUN copy video #{$video->id}: public -> private ({$path})");
                $copied++;

                continue;
            }

            try {
                $stream = $publicDisk->readStream($path);

                if ($stream === false) {
                    throw new \RuntimeException('Unable to read public file stream.');
                }

                $privateDisk->writeStream($path, $stream);

                if (is_resource($stream)) {
                    fclose($stream);
                }

                if (! $this->filesMatch($publicDisk, $privateDisk, $path)) {
                    $privateDisk->delete($path);
                    throw new \RuntimeException('Checksum/size verification failed after copy.');
                }

                $this->info("COPIED video #{$video->id}: {$path}");
                $copied++;

                if ($removeSource) {
                    $publicDisk->delete($path);
                    $removed++;
                    $this->line("  removed public copy: {$path}");
                }
            } catch (\Throwable $exception) {
                $this->error("FAILED video #{$video->id}: {$path} ({$exception->getMessage()})");
                $failed++;
            }
        }

        $this->newLine();
        $this->table(
            ['Metric', 'Count'],
            [
                ['Copied', $copied],
                ['Skipped', $skipped],
                ['Missing source', $missing],
                ['Failed', $failed],
                ['Public copies removed', $removed],
            ],
        );

        if ($dryRun) {
            $this->comment('Dry-run complete. Re-run without --dry-run to apply changes.');
        }

        if ($failed > 0) {
            $this->comment('Production tip: add an nginx/Apache rule to deny /storage/lesson-videos/* as a defense-in-depth layer.');
        }

        return $failed > 0 ? self::FAILURE : self::SUCCESS;
    }

    protected function filesMatch($publicDisk, $privateDisk, string $path): bool
    {
        if (! $publicDisk->exists($path) || ! $privateDisk->exists($path)) {
            return $publicDisk->exists($path) === false
                && $privateDisk->exists($path);
        }

        return $publicDisk->size($path) === $privateDisk->size($path)
            && $publicDisk->checksum($path) === $privateDisk->checksum($path);
    }
}
