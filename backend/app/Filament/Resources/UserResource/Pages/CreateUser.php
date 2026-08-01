<?php

namespace App\Filament\Resources\UserResource\Pages;

use App\Enums\UserRole;
use App\Filament\Resources\UserResource;
use App\Services\PlatformAuditService;
use Filament\Resources\Pages\CreateRecord;

class CreateUser extends CreateRecord
{
    protected static string $resource = UserResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $data['role'] = UserRole::Admin->value;
        $data['password_set_at'] = now();
        $data['email_verified_at'] = now();

        return $data;
    }

    protected function afterCreate(): void
    {
        $this->record->assignRole(UserRole::Admin->value);

        app(PlatformAuditService::class)->logAdmin(
            action: 'admin.created',
            actor: auth()->user(),
            description: 'تم إنشاء المسؤول «'.$this->record->name.'».',
            model: $this->record,
        );
    }
}
