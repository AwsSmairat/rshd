<?php

namespace App\Console\Commands;

use App\Services\Video\VideoStorageAuditService;
use Illuminate\Console\Command;

class AuditVideoStorageCommand extends Command
{
    protected $signature = 'videos:audit-storage
                            {--json : Output machine-readable JSON only}
                            {--skip-bunny : Skip Bunny remote and playback HTTP probes}';

    protected $description = 'Read-only inventory and reconciliation of local video files vs database records';

    public function handle(VideoStorageAuditService $auditService): int
    {
        $verifyRemote = ! (bool) $this->option('skip-bunny');

        $report = $auditService->audit(
            verifyBunnyRemote: $verifyRemote,
            verifyPlaybackHttp: $verifyRemote,
        );

        if ((bool) $this->option('json')) {
            $this->line(json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

            return self::SUCCESS;
        }

        $summary = $report['summary'];

        $this->info('Video storage audit (read-only)');
        $this->table(['Metric', 'Value'], [
            ['Total video records', $summary['total_video_records']],
            ['Bunny ready', $summary['bunny_ready']],
            ['Local migratable', $summary['local_migratable']],
            ['Missing source', $summary['missing_source']],
            ['Orphan files', $summary['orphan_files']],
            ['Duplicate file groups', $summary['duplicate_file_groups']],
            ['Inconsistent records', $summary['inconsistent_records']],
            ['Storage reconciliation', $summary['storage_reconciliation']],
        ]);

        $this->newLine();
        $this->info('Inventory');

        $rows = [];
        foreach ($report['inventory'] as $item) {
            $rows[] = [
                $item['video_id'],
                $item['title'],
                $item['provider'].'/'.$item['status'],
                $item['external_video_id_present'],
                $item['local_source_present'],
                $item['migratable'],
                $item['classification'],
                $item['not_migratable_reason'] ?? '-',
            ];
        }

        $this->table(
            ['ID', 'Title', 'Provider/Status', 'Bunny ID', 'Local', 'Migratable', 'Class', 'Reason'],
            $rows,
        );

        if ($report['orphan_files'] !== []) {
            $this->warn('Orphan local video files (not linked to any record):');
            $this->table(['File', 'Size bytes', 'Checksum prefix'], array_map(
                fn (array $file): array => [
                    $file['relative_path'],
                    $file['size_bytes'],
                    substr($file['checksum_sha256'], 0, 12).'…',
                ],
                $report['orphan_files'],
            ));
        }

        if ($report['duplicate_file_groups'] !== []) {
            $this->warn('Duplicate local file groups (same checksum):');
            foreach ($report['duplicate_file_groups'] as $group) {
                $this->line('- '.implode(', ', $group['paths']));
            }
        }

        if ($report['inconsistent_records'] !== []) {
            $this->warn('Inconsistent records:');
            foreach ($report['inconsistent_records'] as $record) {
                $this->line("#{$record['video_id']}: ".implode('; ', $record['reasons']));
            }
        }

        $this->newLine();
        $this->line('Safe batch candidates: '.($summary['safe_batch_candidates'] === [] ? 'none' : implode(', ', $summary['safe_batch_candidates'])));
        $this->line('Needs manual recovery: '.($summary['needs_manual_recovery'] === [] ? 'none' : implode(', ', $summary['needs_manual_recovery'])));

        return self::SUCCESS;
    }
}
