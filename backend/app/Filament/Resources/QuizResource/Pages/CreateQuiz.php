<?php

namespace App\Filament\Resources\QuizResource\Pages;

use App\Enums\AccessStatus;
use App\Enums\PaymentStatus;
use App\Filament\Resources\QuizResource;
use App\Services\PlatformNotificationService;
use Filament\Resources\Pages\CreateRecord;

class CreateQuiz extends CreateRecord
{
    protected static string $resource = QuizResource::class;

    protected function afterCreate(): void
    {
        $quiz = $this->record->loadMissing('subject');
        $subject = $quiz->subject;

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
                title: 'اختبار جديد',
                body: 'تم إضافة اختبار «'.$quiz->title.'» في مادة «'.$subject->title.'».',
                type: 'quiz_created',
                settingKey: 'notify_student_quiz_created',
                data: [
                    'quiz_id' => $quiz->id,
                    'subject_id' => $subject->id,
                ],
            );
        }
    }
}
