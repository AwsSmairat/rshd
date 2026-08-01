<?php

namespace App\Filament\Resources\NotificationResource\Pages;

use App\Filament\Resources\NotificationResource;
use App\Services\PlatformAuditService;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditNotification extends EditRecord
{
    protected static string $resource = NotificationResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make()
                ->before(function (): void {
                    app(PlatformAuditService::class)->logAdmin(
                        action: 'notification.deleted',
                        actor: auth()->user(),
                        description: 'تم حذف الإشعار «'.$this->record->title.'».',
                        model: $this->record,
                    );
                }),
        ];
    }

    protected function afterSave(): void
    {
        app(PlatformAuditService::class)->logAdmin(
            action: 'notification.updated',
            actor: auth()->user(),
            description: 'تم تحديث الإشعار «'.$this->record->title.'».',
            model: $this->record,
        );
    }

    protected function getSavedNotificationTitle(): ?string
    {
        return 'تم تحديث الإشعار';
    }
}
