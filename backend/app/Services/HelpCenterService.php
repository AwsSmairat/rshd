<?php

namespace App\Services;

use App\Enums\AccessStatus;
use App\Enums\AppNotificationType;
use App\Enums\ContentStatus;
use App\Enums\PaymentStatus;
use App\Models\AppNotification;
use App\Models\Subject;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Validation\ValidationException;

class HelpCenterService
{
    public function __construct(
        protected PlatformSettingsService $settings,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function contactsForStudent(User $student): array
    {
        $subjects = $student->enrolledSubjects()
            ->wherePivot('payment_status', PaymentStatus::Paid)
            ->wherePivot('access_status', AccessStatus::Active)
            ->where('subjects.status', ContentStatus::Active)
            ->with('instructor')
            ->orderBy('subjects.title')
            ->get();

        return [
            'support_email' => (string) $this->settings->get(
                'support_email',
                'admin@rshdacademy.com',
                'platform',
            ),
            'support_phone' => (string) $this->settings->get(
                'support_phone',
                '',
                'platform',
            ),
            'teachers' => $this->mapTeacherContacts($subjects),
        ];
    }

    /**
     * @param  Collection<int, Subject>  $subjects
     * @return list<array<string, mixed>>
     */
    protected function mapTeacherContacts(Collection $subjects): array
    {
        return $subjects
            ->map(function (Subject $subject): array {
                $instructor = $subject->instructor;
                $directEmail = ($instructor !== null && $instructor->emailVisibleToStudents())
                    ? $instructor->email
                    : null;

                return [
                    'subject_id' => $subject->id,
                    'subject_title' => $subject->title,
                    'instructor_id' => $instructor?->id,
                    'instructor_name' => $instructor?->name ?? '—',
                    'contact_email' => $directEmail,
                    'contact_via_support' => $directEmail === null,
                ];
            })
            ->values()
            ->all();
    }

    public function sendMessageToInstructor(
        User $student,
        int $subjectId,
        string $message,
    ): AppNotification {
        $subject = $student->enrolledSubjects()
            ->where('subjects.id', $subjectId)
            ->wherePivot('payment_status', PaymentStatus::Paid)
            ->wherePivot('access_status', AccessStatus::Active)
            ->where('subjects.status', ContentStatus::Active)
            ->with('instructor')
            ->first();

        if ($subject === null) {
            throw ValidationException::withMessages([
                'subject_id' => ['لا تملك وصولاً نشطاً لهذه المادة.'],
            ]);
        }

        $instructor = $subject->instructor;

        if ($instructor === null) {
            throw ValidationException::withMessages([
                'subject_id' => ['لا يوجد مدرّس مرتبط بهذه المادة.'],
            ]);
        }

        $body = trim($message);
        $studentName = trim((string) $student->name) !== '' ? $student->name : 'طالب';

        return AppNotification::query()->create([
            'user_id' => $instructor->id,
            'title' => "رسالة من {$studentName} — {$subject->title}",
            'body' => $body,
            'type' => AppNotificationType::StudentMessage->value,
            'data' => [
                'student_id' => $student->id,
                'student_name' => $studentName,
                'subject_id' => $subject->id,
                'subject_title' => $subject->title,
            ],
            'is_read' => false,
        ]);
    }
}
