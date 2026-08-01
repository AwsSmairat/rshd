<?php

namespace App\Enums;

enum AppNotificationType: string
{
    case SubjectActivated = 'subject_activated';
    case ActivationRequest = 'activation_request';
    case AssignmentCreated = 'assignment_created';
    case QuizCreated = 'quiz_created';
    case GradePublished = 'grade_published';
    case Announcement = 'announcement';
    case AssignmentSubmitted = 'assignment_submitted';
    case StudentMessage = 'student_message';
    case InstructorReply = 'instructor_reply';
    case Custom = 'custom';

    public function label(): string
    {
        return match ($this) {
            self::SubjectActivated => 'تفعيل مادة',
            self::ActivationRequest => 'طلب تفعيل',
            self::AssignmentCreated => 'واجب جديد',
            self::QuizCreated => 'اختبار جديد',
            self::GradePublished => 'درجة منشورة',
            self::Announcement => 'إعلان',
            self::AssignmentSubmitted => 'تسليم واجب',
            self::StudentMessage => 'رسالة من طالب',
            self::InstructorReply => 'رد من المدرّس',
            self::Custom => 'إشعار مخصص',
        };
    }

    /**
     * @return array<string, string>
     */
    public static function options(): array
    {
        return collect(self::cases())
            ->mapWithKeys(fn (self $case): array => [$case->value => $case->label()])
            ->all();
    }

    /**
     * @return array<string, string>
     */
    public static function manualFormOptions(): array
    {
        return collect(self::cases())
            ->reject(fn (self $case): bool => $case === self::ActivationRequest)
            ->mapWithKeys(fn (self $case): array => [$case->value => $case->label()])
            ->all();
    }

    public static function labelFor(?string $value): string
    {
        if ($value === null || $value === '') {
            return '—';
        }

        return self::tryFrom($value)?->label() ?? $value;
    }
}
