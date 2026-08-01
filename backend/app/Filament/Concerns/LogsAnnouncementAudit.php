<?php

namespace App\Filament\Concerns;

use App\Models\Announcement;
use App\Services\PlatformAuditService;

trait LogsAnnouncementAudit
{
    protected function logAnnouncementAudit(string $action, Announcement $announcement, string $description): void
    {
        $audit = app(PlatformAuditService::class);
        $actor = auth()->user();

        if ($actor?->isInstructor()) {
            $audit->logInstructor(
                action: $action,
                actor: $actor,
                description: $description,
                model: $announcement,
            );

            return;
        }

        $audit->logAdmin(
            action: $action,
            actor: $actor,
            description: $description,
            model: $announcement,
        );
    }
}
