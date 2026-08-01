<?php

namespace App\Filament\Resources\AnnouncementResource\Pages;

use App\Enums\AnnouncementTargetType;
use App\Filament\Concerns\LogsAnnouncementAudit;
use App\Filament\Resources\AnnouncementResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditAnnouncement extends EditRecord
{
    use LogsAnnouncementAudit;

    protected static string $resource = AnnouncementResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make()
                ->before(function (): void {
                    $this->logAnnouncementAudit(
                        action: 'announcement.deleted',
                        announcement: $this->record,
                        description: 'تم حذف الإعلان «'.$this->record->title.'».',
                    );
                }),
        ];
    }

    protected function mutateFormDataBeforeSave(array $data): array
    {
        if (($data['target_type'] ?? null) !== AnnouncementTargetType::Subject->value) {
            $data['subject_id'] = null;
        }

        return $data;
    }

    protected function afterSave(): void
    {
        $this->logAnnouncementAudit(
            action: 'announcement.updated',
            announcement: $this->record,
            description: 'تم تحديث الإعلان «'.$this->record->title.'».',
        );
    }

    protected function getSavedNotificationTitle(): ?string
    {
        return 'تم تحديث الإعلان';
    }
}
