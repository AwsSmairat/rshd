<?php

namespace App\Console\Commands;

use App\Services\LessonFiles\LessonFileBunnyStorageAuditService;
use Illuminate\Console\Command;

class AuditBunnyLessonFileStorageCommand extends Command
{
    protected $signature = 'files:audit-bunny-storage {--json : Output machine-readable JSON only}';

    protected $description = 'Read-only audit of Bunny Storage lesson-files objects vs database external_path values';

    public function handle(LessonFileBunnyStorageAuditService $auditService): int
    {
        $report = $auditService->audit();

        if ((bool) $this->option('json')) {
            $this->line(json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

            return self::SUCCESS;
        }

        $summary = $report['summary'];

        $this->info('Bunny lesson-files storage audit (read-only)');
        $this->table(['Metric', 'Value'], [
            ['Bunny configured', $summary['bunny_configured'] ? 'yes' : 'no'],
            ['Remote objects', $summary['remote_objects']],
            ['Linked objects', $summary['linked_objects']],
            ['Orphan objects', $summary['orphan_objects']],
            ['Missing remote objects', $summary['missing_remote_objects']],
            ['Duplicate DB paths', $summary['duplicate_db_paths']],
            ['Duplicate remote groups', $summary['duplicate_remote_groups']],
        ]);

        if ($report['orphans'] !== []) {
            $this->warn('Orphan Bunny objects:');
            $this->table(
                ['Path', 'Size bytes'],
                array_map(
                    fn (array $item): array => [$item['path'], $item['size_bytes']],
                    $report['orphans'],
                ),
            );
        }

        if ($report['missing_remote'] !== []) {
            $this->warn('Missing remote objects:');
            $this->table(
                ['File ID', 'external_path'],
                array_map(
                    fn (array $item): array => [$item['file_id'], $item['external_path']],
                    $report['missing_remote'],
                ),
            );
        }

        return self::SUCCESS;
    }
}
