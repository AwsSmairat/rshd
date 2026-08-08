<?php

namespace App\Console\Commands;

use App\Services\Video\VideoStorageRepairService;
use Illuminate\Console\Command;

class RepairVideoStorageCommand extends Command
{
    protected $signature = 'videos:repair-storage
                            {--dry-run : Preview repairs without writing changes}
                            {--apply : Apply deterministic repairs}';

    protected $description = 'Apply deterministic video storage reconciliation repairs (never deletes records or files)';

    public function handle(VideoStorageRepairService $repairService): int
    {
        $apply = (bool) $this->option('apply');
        $dryRun = ! $apply || (bool) $this->option('dry-run');

        if (! $apply) {
            $this->warn('Running in dry-run mode. Pass --apply to write changes.');
        }

        $result = $repairService->repair($dryRun);

        if ($result['changes'] === []) {
            $this->info('No deterministic repairs needed.');

            return self::SUCCESS;
        }

        foreach ($result['changes'] as $change) {
            $this->line("Video #{$change['video_id']}: {$change['title']}");
            foreach ($change['actions'] as $action) {
                $this->line('  - '.json_encode($action, JSON_UNESCAPED_UNICODE));
            }
        }

        $this->comment($dryRun ? 'Dry-run complete.' : 'Repairs applied.');

        return self::SUCCESS;
    }
}
