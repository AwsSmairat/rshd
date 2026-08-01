<?php

namespace App\Console\Commands;

use App\Services\PlatformAuditService;
use Illuminate\Console\Command;

class PruneAuditLogsCommand extends Command
{
    protected $signature = 'platform:prune-audit-logs';

    protected $description = 'Remove audit logs older than the configured retention period';

    public function handle(PlatformAuditService $auditService): int
    {
        $deleted = $auditService->pruneExpired();
        $this->info("Pruned {$deleted} audit log(s).");

        return self::SUCCESS;
    }
}
