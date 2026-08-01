<?php

namespace App\Filament\Concerns;

use App\Models\Expense;
use App\Services\PlatformAuditService;

trait LogsExpenseAudit
{
    protected function logExpenseAudit(string $action, Expense $expense, string $description): void
    {
        app(PlatformAuditService::class)->logFinancial(
            action: $action,
            actor: auth()->user(),
            description: $description,
            model: $expense,
        );
    }
}
