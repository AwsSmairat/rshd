<?php

namespace App\Filament\Resources\StudentResource\Pages;

use App\Enums\UserRole;
use App\Filament\Resources\StudentResource;
use App\Services\PlatformAuditService;
use Filament\Resources\Pages\CreateRecord;

class CreateStudent extends CreateRecord
{
    protected static string $resource = StudentResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $data['role'] = UserRole::Student->value;
        $data['password_set_at'] = now();

        if ($data['mark_email_verified'] ?? true) {
            $data['email_verified_at'] = now();
        }

        unset($data['mark_email_verified']);

        return $data;
    }

    protected function afterCreate(): void
    {
        $this->record->assignRole(UserRole::Student->value);

        app(PlatformAuditService::class)->logAdmin(
            action: 'student.created',
            actor: auth()->user(),
            description: 'تم إنشاء الطالب «'.$this->record->name.'».',
            model: $this->record,
        );
    }
}
