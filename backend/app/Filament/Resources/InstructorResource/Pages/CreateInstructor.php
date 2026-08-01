<?php

namespace App\Filament\Resources\InstructorResource\Pages;

use App\Enums\UserRole;
use App\Filament\Resources\InstructorResource;
use App\Services\InstructorInvitationService;
use App\Services\PlatformAuditService;
use App\Services\PlatformSettingsService;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\CreateRecord;

class CreateInstructor extends CreateRecord
{
    protected static string $resource = InstructorResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $data['role'] = UserRole::Instructor->value;
        $data['password'] = null;

        return $data;
    }

    protected function afterCreate(): void
    {
        $this->record->assignRole(UserRole::Instructor->value);

        app(InstructorInvitationService::class)->sendInvitation($this->record);

        app(PlatformAuditService::class)->logAdmin(
            action: 'instructor.created',
            actor: auth()->user(),
            description: 'تم إنشاء المدرس «'.$this->record->name.'».',
            model: $this->record,
        );

        $settings = app(PlatformSettingsService::class);

        if ($settings->enabled('instructor_invitation_email_enabled', 'email')) {
            Notification::make()
                ->title('تم إرسال دعوة تعيين كلمة المرور')
                ->success()
                ->send();

            return;
        }

        Notification::make()
            ->title('تم إنشاء المدرس')
            ->body('إرسال البريد معطّل في إعدادات المنصة — استخدم «إعادة إرسال» لاحقاً أو فعّل البريد.')
            ->warning()
            ->send();
    }
}
