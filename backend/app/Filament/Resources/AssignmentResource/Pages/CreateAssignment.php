<?php

namespace App\Filament\Resources\AssignmentResource\Pages;

use App\Enums\AccessStatus;
use App\Enums\PaymentStatus;
use App\Filament\Resources\AssignmentResource;
use App\Services\PlatformNotificationService;
use Filament\Resources\Pages\CreateRecord;

class CreateAssignment extends CreateRecord
{
    protected static string $resource = AssignmentResource::class;

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    protected function mutateFormDataBeforeCreate(array $data): array
    {
        return AssignmentResource::prepareAttachmentData($data);
    }

    protected function afterCreate(): void
    {
        $assignment = $this->record->loadMissing('subject');
        $subject = $assignment->subject;

        if ($subject === null) {
            return;
        }

        $students = $subject->students()
            ->wherePivot('payment_status', PaymentStatus::Paid)
            ->wherePivot('access_status', AccessStatus::Active)
            ->get();

        $notifications = app(PlatformNotificationService::class);

        foreach ($students as $student) {
            $notifications->notifyUser(
                user: $student,
                title: 'واجب جديد',
                body: 'تم إضافة واجب «'.$assignment->title.'» في مادة «'.$subject->title.'».',
                type: 'assignment_created',
                settingKey: 'notify_student_assignment_created',
                data: [
                    'assignment_id' => $assignment->id,
                    'subject_id' => $subject->id,
                ],
            );
        }
    }
}
