<?php

namespace App\Filament\Resources\AnnouncementResource\Pages;

use App\Enums\AnnouncementTargetType;
use App\Filament\Concerns\HasInstructorScope;
use App\Filament\Concerns\LogsAnnouncementAudit;
use App\Filament\Resources\AnnouncementResource;
use App\Services\AnnouncementService;
use Filament\Resources\Pages\CreateRecord;

class CreateAnnouncement extends CreateRecord
{
    use HasInstructorScope;
    use LogsAnnouncementAudit;

    protected static string $resource = AnnouncementResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        if (static::isInstructor()) {
            $data['instructor_id'] = static::authUser()?->id;
        }

        if (($data['target_type'] ?? null) !== AnnouncementTargetType::Subject->value) {
            $data['subject_id'] = null;
        }

        return $data;
    }

    protected function afterCreate(): void
    {
        $this->logAnnouncementAudit(
            action: 'announcement.created',
            announcement: $this->record,
            description: 'تم نشر الإعلان «'.$this->record->title.'».',
        );

        app(AnnouncementService::class)->notifyAffectedStudents($this->record);
    }

    protected function getCreatedNotificationTitle(): ?string
    {
        return 'تم نشر الإعلان';
    }
}
