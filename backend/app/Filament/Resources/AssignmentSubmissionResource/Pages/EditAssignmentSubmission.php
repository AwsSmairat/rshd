<?php

namespace App\Filament\Resources\AssignmentSubmissionResource\Pages;

use App\Enums\GradeSourceType;
use App\Filament\Resources\AssignmentSubmissionResource;
use App\Models\Grade;
use App\Services\PlatformNotificationService;
use Filament\Resources\Pages\EditRecord;

class EditAssignmentSubmission extends EditRecord
{
    protected static string $resource = AssignmentSubmissionResource::class;

    protected function getHeaderActions(): array
    {
        return [];
    }

    protected function afterSave(): void
    {
        if (! $this->record->wasChanged('grade') || $this->record->grade === null) {
            return;
        }

        $this->record->loadMissing(['assignment.subject', 'student']);
        $assignment = $this->record->assignment;
        $student = $this->record->student;

        if ($assignment === null || $student === null) {
            return;
        }

        Grade::query()->updateOrCreate(
            [
                'student_id' => $student->id,
                'subject_id' => $assignment->subject_id,
                'source_type' => GradeSourceType::Assignment,
                'source_id' => $assignment->id,
            ],
            [
                'grade' => $this->record->grade,
            ],
        );

        app(PlatformNotificationService::class)->notifyUser(
            user: $student,
            title: 'تم نشر درجة الواجب',
            body: 'درجتك في واجب «'.$assignment->title.'»: '.$this->record->grade,
            type: 'grade_published',
            settingKey: 'notify_student_grade_published',
        );
    }
}
