<?php

namespace App\Console\Commands;

use App\Jobs\UploadVideoToBunnyJob;
use App\Models\Video;
use App\Services\Bunny\BunnyStreamService;
use Illuminate\Console\Command;

class MigrateVideosToBunnyCommand extends Command
{
    protected $signature = 'videos:migrate-to-bunny
                            {--dry-run : Preview which videos would be queued}
                            {--video= : Migrate a single internal video id only}';

    protected $description = 'Queue local lesson videos for upload to Bunny Stream';

    public function handle(BunnyStreamService $bunnyStream): int
    {
        if (! $bunnyStream->isConfigured()) {
            $this->error('Bunny Stream is not fully configured. Set API, token, and CDN env vars first.');

            return self::FAILURE;
        }

        $dryRun = (bool) $this->option('dry-run');
        $singleVideoId = $this->option('video');

        $query = Video::query()
            ->whereNotNull('video_path')
            ->where('video_path', '!=', '')
            ->where(function ($builder): void {
                $builder->whereNull('external_video_id')
                    ->orWhere('external_video_id', '');
            })
            ->whereIn('storage_provider', ['local', 'bunny'])
            ->orderBy('id');

        if ($singleVideoId !== null) {
            $query->whereKey((int) $singleVideoId);
        }

        $videos = $query->get();

        if ($videos->isEmpty()) {
            $this->info('No eligible videos found for Bunny upload.');

            return self::SUCCESS;
        }

        $queued = 0;
        $skipped = 0;

        foreach ($videos as $video) {
            if ($video->external_video_id) {
                $this->line("SKIP #{$video->id}: already has Bunny id");
                $skipped++;

                continue;
            }

            if ($dryRun) {
                $this->line("DRY-RUN queue #{$video->id}: {$video->title}");
                $queued++;

                continue;
            }

            UploadVideoToBunnyJob::dispatch($video->id);
            $this->info("QUEUED #{$video->id}: {$video->title}");
            $queued++;
        }

        $this->table(['Metric', 'Count'], [
            ['Queued', $queued],
            ['Skipped', $skipped],
        ]);

        if ($dryRun) {
            $this->comment('Dry-run complete. Re-run without --dry-run to queue uploads.');
        } else {
            $this->comment('Ensure a queue worker is running to process Bunny uploads.');
        }

        return self::SUCCESS;
    }
}
