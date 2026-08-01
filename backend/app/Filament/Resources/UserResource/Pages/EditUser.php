<?php

namespace App\Filament\Resources\UserResource\Pages;

use App\Enums\UserRole;
use App\Filament\Resources\UserResource;
use App\Services\PlatformAuditService;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditUser extends EditRecord
{
    protected static string $resource = UserResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make()
                ->before(function (): void {
                    app(PlatformAuditService::class)->logAdmin(
                        action: 'admin.deleted',
                        actor: auth()->user(),
                        description: 'تم حذف المسؤول «'.$this->record->name.'».',
                        model: $this->record,
                    );
                }),
        ];
    }

    protected function mutateFormDataBeforeSave(array $data): array
    {
        $data['role'] = $this->record->role instanceof UserRole
            ? $this->record->role->value
            : UserRole::Admin->value;

        if (filled($data['password'] ?? null)) {
            $data['password_set_at'] = now();
        }

        return $data;
    }

    protected function afterSave(): void
    {
        app(PlatformAuditService::class)->logAdmin(
            action: 'admin.updated',
            actor: auth()->user(),
            description: 'تم تحديث بيانات المسؤول «'.$this->record->name.'».',
            model: $this->record,
        );
    }
}
