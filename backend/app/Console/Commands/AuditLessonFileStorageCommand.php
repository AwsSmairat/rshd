<?php

namespace App\Console\Commands;

use App\Services\LessonFiles\LessonFileStorageAuditService;
use Illuminate\Console\Command;

class AuditLessonFileStorageCommand extends Command
{
    protected $signature = 'files:audit-storage {--json : Output machine-readable JSON only}';

    protected $description = 'Read-only audit of local lesson file storage vs database records';

    public function handle(LessonFileStorageAuditService $auditService): int
    {
        $report = $auditService->audit();

        if ((bool) $this->option('json')) {
            $this->line(json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

            return self::SUCCESS;
        }

        $summary = $report['summary'];

        $this->info('Lesson file storage audit (read-only)');
        $this->table(['Metric', 'Value'], [
            ['Total records', $summary['total_records']],
            ['Public PDF files', $summary['public_pdf_files']],
            ['Permanent public URLs', $summary['permanent_public_urls']],
            ['Local orphan files', $summary['local_orphan_files']],
            ['Inconsistent records', $summary['inconsistent_records']],
        ]);

        if ($report['inconsistent_records'] !== []) {
            $this->warn('Inconsistent records:');
            foreach ($report['inconsistent_records'] as $record) {
                $this->line("#{$record['file_id']}: ".implode('; ', $record['reasons']));
            }
        }

        return self::SUCCESS;
    }
}
