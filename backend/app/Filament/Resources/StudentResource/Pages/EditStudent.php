<?php

namespace App\Filament\Resources\StudentResource\Pages;

use App\Filament\Resources\StudentResource;
use App\Services\PlatformAuditService;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditStudent extends EditRecord
{
    protected static string $resource = StudentResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make()
                ->before(function (): void {
                    app(PlatformAuditService::class)->logAdmin(
                        action: 'student.deleted',
                        actor: auth()->user(),
                        description: 'تم حذف الطالب «'.$this->record->name.'».',
                        model: $this->record,
                    );
                }),
        ];
    }

    protected function afterSave(): void
    {
        app(PlatformAuditService::class)->logAdmin(
            action: 'student.updated',
            actor: auth()->user(),
            description: 'تم تحديث بيانات الطالب «'.$this->record->name.'».',
            model: $this->record,
        );
    }
}
