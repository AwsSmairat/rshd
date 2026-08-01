<?php

namespace App\Services;

use App\Enums\AccessStatus;
use App\Enums\AppNotificationType;
use App\Enums\ContentStatus;
use App\Enums\PaymentStatus;
use App\Models\AppNotification;
use App\Models\Subject;
use App\Models\User;
use Illuminate\Validation\ValidationException;

class InstructorMessageService
{
    public function replyToStudentMessage(
        User $instructor,
        AppNotification $incomingMessage,
        string $replyBody,
    ): AppNotification {
        if ($incomingMessage->user_id !== $instructor->id) {
            throw ValidationException::withMessages([
                'reply' => ['لا يمكنك الرد على هذه الرسالة.'],
            ]);
        }

        if ($incomingMessage->type !== AppNotificationType::StudentMessage->value) {
            throw ValidationException::withMessages([
                'reply' => ['يمكن الرد فقط على رسائل الطلاب.'],
            ]);
        }

        $messageData = is_array($incomingMessage->data) ? $incomingMessage->data : [];
        $studentId = isset($messageData['student_id']) ? (int) $messageData['student_id'] : 0;
        $subjectId = isset($messageData['subject_id']) ? (int) $messageData['subject_id'] : 0;

        if ($studentId <= 0 || $subjectId <= 0) {
            throw ValidationException::withMessages([
                'reply' => ['بيانات الرسالة غير مكتملة.'],
            ]);
        }

        $student = User::query()->find($studentId);

        if ($student === null || ! $student->isStudent()) {
            throw ValidationException::withMessages([
                'reply' => ['الطالب المرتبط بهذه الرسالة غير موجود.'],
            ]);
        }

        $subject = Subject::query()
            ->whereKey($subjectId)
            ->where('instructor_id', $instructor->id)
            ->where('status', ContentStatus::Active)
            ->first();

        if ($subject === null) {
            throw ValidationException::withMessages([
                'reply' => ['لا يمكنك الرد على رسائل هذه المادة.'],
            ]);
        }

        $isEnrolled = $student->enrolledSubjects()
            ->where('subjects.id', $subject->id)
            ->wherePivot('payment_status', PaymentStatus::Paid)
            ->wherePivot('access_status', AccessStatus::Active)
            ->exists();

        if (! $isEnrolled) {
            throw ValidationException::withMessages([
                'reply' => ['الطالب لم يعد مسجّلاً في هذه المادة.'],
            ]);
        }

        $body = trim($replyBody);

        if ($body === '' || mb_strlen($body) < 3) {
            throw ValidationException::withMessages([
                'reply' => ['يجب أن يكون الرد 3 أحرف على الأقل.'],
            ]);
        }

        $instructorName = trim((string) $instructor->name) !== ''
            ? $instructor->name
            : 'المدرّس';

        $reply = AppNotification::query()->create([
            'user_id' => $student->id,
            'title' => "رد من {$instructorName} — {$subject->title}",
            'body' => $body,
            'type' => AppNotificationType::InstructorReply->value,
            'data' => [
                'instructor_id' => $instructor->id,
                'instructor_name' => $instructorName,
                'subject_id' => $subject->id,
                'subject_title' => $subject->title,
                'in_reply_to_id' => $incomingMessage->id,
            ],
            'is_read' => false,
        ]);

        $incomingMessage->update([
            'is_read' => true,
            'data' => array_merge($messageData, [
                'replied_at' => now()->toIso8601String(),
                'reply_id' => $reply->id,
            ]),
        ]);

        return $reply;
    }
}
