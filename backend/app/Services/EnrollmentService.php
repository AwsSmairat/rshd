<?php

namespace App\Services;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\PaymentStatus;
use App\Enums\UserRole;
use App\Models\Subject;
use App\Models\SubjectStudent;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Validation\ValidationException;

class EnrollmentService
{
    public function __construct(
        protected PlatformSettingsService $settings,
        protected PlatformNotificationService $notifications,
        protected PlatformAuditService $audit,
    ) {}

    public function checkStudentAccessToSubject(User $student, Subject $subject): bool
    {
        return SubjectStudent::query()
            ->where('student_id', $student->id)
            ->where('subject_id', $subject->id)
            ->where('payment_status', PaymentStatus::Paid)
            ->where('access_status', AccessStatus::Active)
            ->exists();
    }

    public function requestPurchase(User $student, Subject $subject): SubjectStudent
    {
        if (! $student->isStudent()) {
            throw ValidationException::withMessages([
                'subject' => ['طلبات الشراء متاحة للطلاب فقط.'],
            ]);
        }

        if (! $this->settings->enabled('cash_payment_enabled', 'payments')) {
            throw ValidationException::withMessages([
                'subject' => ['الدفع النقدي غير مفعّل حالياً.'],
            ]);
        }

        if ($subject->status !== ContentStatus::Active) {
            throw ValidationException::withMessages([
                'subject' => ['هذه المادة غير متاحة حالياً.'],
            ]);
        }

        $existing = SubjectStudent::query()
            ->where('student_id', $student->id)
            ->where('subject_id', $subject->id)
            ->first();

        if ($existing !== null) {
            if ($existing->payment_status === PaymentStatus::Paid
                && $existing->access_status === AccessStatus::Active) {
                throw ValidationException::withMessages([
                    'subject' => ['هذه المادة مفعّلة لديك مسبقاً.'],
                ]);
            }

            if ($existing->access_status === AccessStatus::Pending
                || $existing->payment_status === PaymentStatus::Unpaid) {
                throw ValidationException::withMessages([
                    'subject' => ['لديك طلب شراء قيد المراجعة لهذه المادة.'],
                ]);
            }
        }

        $enrollment = $existing ?? new SubjectStudent([
            'subject_id' => $subject->id,
            'student_id' => $student->id,
        ]);

        $defaultActivation = $this->settings->stringValue('default_activation_status', 'pending', 'payments');
        $enrollment->payment_status = PaymentStatus::Unpaid;
        $enrollment->access_status = $defaultActivation === 'approved'
            ? AccessStatus::Active
            : AccessStatus::Pending;
        $enrollment->activated_by = null;
        $enrollment->activated_at = null;
        $enrollment->save();

        $this->audit->logActivation(
            'enrollment.requested',
            $student,
            'طلب تفعيل مادة «'.$subject->title.'».',
            $enrollment,
        );

        $this->notifications->notifyAdmins(
            title: 'طلب تفعيل جديد',
            body: 'الطالب «'.$student->name.'» طلب تفعيل مادة «'.$subject->title.'».',
            type: 'activation_request',
            settingKey: 'notify_admin_activation_request',
        );

        if (! $this->settings->enabled('manual_activation_required', 'payments')) {
            $admin = User::query()->where('role', UserRole::Admin)->first();
            if ($admin !== null) {
                return $this->activateStudent($student, $subject, $admin);
            }
        }

        return $enrollment;
    }

    public function cancelPurchaseRequest(User $student, Subject $subject): void
    {
        if (! $student->isStudent()) {
            throw ValidationException::withMessages([
                'subject' => ['إلغاء الطلب متاح للطلاب فقط.'],
            ]);
        }

        $enrollment = SubjectStudent::query()
            ->where('student_id', $student->id)
            ->where('subject_id', $subject->id)
            ->first();

        if ($enrollment === null) {
            throw ValidationException::withMessages([
                'subject' => ['لا يوجد طلب شراء لهذه المادة.'],
            ]);
        }

        if ($enrollment->payment_status === PaymentStatus::Paid
            && $enrollment->access_status === AccessStatus::Active) {
            throw ValidationException::withMessages([
                'subject' => ['لا يمكن إلغاء مادة مفعّلة.'],
            ]);
        }

        if ($enrollment->access_status !== AccessStatus::Pending
            && $enrollment->payment_status !== PaymentStatus::Unpaid) {
            throw ValidationException::withMessages([
                'subject' => ['لا يمكن إلغاء هذا الطلب.'],
            ]);
        }

        $enrollment->delete();

        $this->audit->logActivation(
            'enrollment.cancelled',
            $student,
            'ألغى الطالب طلب تفعيل مادة «'.$subject->title.'».',
        );
    }

    public function activateStudent(
        User $student,
        Subject $subject,
        User $activatedBy,
        ?Carbon $expiresAt = null,
    ): SubjectStudent {
        $enrollment = SubjectStudent::query()->firstOrNew([
            'subject_id' => $subject->id,
            'student_id' => $student->id,
        ]);

        $enrollment->payment_status = PaymentStatus::Paid;
        $enrollment->access_status = AccessStatus::Active;
        $enrollment->activated_by = $activatedBy->id;

        if ($enrollment->sale_price === null && $this->settings->enabled('auto_use_subject_price', 'payments')) {
            $enrollment->sale_price = $subject->price ?? 0;
        }

        if ($enrollment->paid_at === null) {
            $enrollment->paid_at = now();
        }

        if ($enrollment->activated_at === null) {
            $enrollment->activated_at = now();
        }

        if ($expiresAt !== null) {
            $enrollment->expires_at = $expiresAt;
        }

        $enrollment->save();

        $this->audit->logActivation(
            'enrollment.activated',
            $activatedBy,
            'تم تفعيل مادة «'.$subject->title.'» للطالب «'.$student->name.'».',
            $enrollment,
        );

        $this->notifications->notifyUser(
            user: $student,
            title: 'تم تفعيل مادة',
            body: 'تم تفعيل مادة «'.$subject->title.'». يمكنك الآن الوصول إلى محتواها.',
            type: 'subject_activated',
            settingKey: 'notify_student_subject_activated',
            data: [
                'subject_id' => $subject->id,
            ],
        );

        return $enrollment;
    }

    public function revokeAccess(User $student, Subject $subject, ?User $actor = null): void
    {
        SubjectStudent::query()
            ->where('student_id', $student->id)
            ->where('subject_id', $subject->id)
            ->update(['access_status' => AccessStatus::Revoked]);

        $this->audit->logActivation(
            'enrollment.revoked',
            $actor,
            'تم إلغاء تفعيل مادة «'.$subject->title.'» للطالب «'.$student->name.'».',
        );
    }

    /**
     * @return 'none'|'pending'|'active'
     */
    public function enrollmentStatusFor(User $student, Subject $subject): string
    {
        $enrollment = SubjectStudent::query()
            ->where('student_id', $student->id)
            ->where('subject_id', $subject->id)
            ->first();

        if ($enrollment === null) {
            return 'none';
        }

        if ($enrollment->payment_status === PaymentStatus::Paid
            && $enrollment->access_status === AccessStatus::Active) {
            return 'active';
        }

        if ($enrollment->access_status === AccessStatus::Pending
            || $enrollment->payment_status === PaymentStatus::Unpaid) {
            return 'pending';
        }

        return 'none';
    }
}
