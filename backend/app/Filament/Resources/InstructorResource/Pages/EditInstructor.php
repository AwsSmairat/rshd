<?php

namespace App\Filament\Resources\InstructorResource\Pages;

use App\Filament\Resources\InstructorResource;
use App\Services\PlatformAuditService;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditInstructor extends EditRecord
{
    protected static string $resource = InstructorResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make()
                ->before(function (): void {
                    app(PlatformAuditService::class)->logAdmin(
                        action: 'instructor.deleted',
                        actor: auth()->user(),
                        description: 'تم حذف المدرس «'.$this->record->name.'».',
                        model: $this->record,
                    );
                }),
        ];
    }

    protected function afterSave(): void
    {
        app(PlatformAuditService::class)->logAdmin(
            action: 'instructor.updated',
            actor: auth()->user(),
            description: 'تم تحديث بيانات المدرس «'.$this->record->name.'».',
            model: $this->record,
        );
    }
}
