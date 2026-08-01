<?php

namespace App\Filament\Resources\GradeResource\Pages;

use App\Filament\Resources\GradeResource;
use App\Services\PlatformNotificationService;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditGrade extends EditRecord
{
    protected static string $resource = GradeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }

    protected function afterSave(): void
    {
        if (! $this->record->wasChanged('grade')) {
            return;
        }

        $this->record->loadMissing(['student', 'subject']);
        $student = $this->record->student;

        if ($student === null) {
            return;
        }

        app(PlatformNotificationService::class)->notifyUser(
            user: $student,
            title: 'تم نشر درجة',
            body: 'تم تحديث درجتك في مادة «'.($this->record->subject?->title ?? '').'».',
            type: 'grade_published',
            settingKey: 'notify_student_grade_published',
            data: [
                'grade_id' => $this->record->id,
                'subject_id' => $this->record->subject_id,
            ],
        );
    }
}
