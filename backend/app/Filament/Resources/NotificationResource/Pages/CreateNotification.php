<?php

namespace App\Filament\Resources\NotificationResource\Pages;

use App\Enums\AccessStatus;
use App\Enums\AppNotificationType;
use App\Enums\PaymentStatus;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Filament\Resources\NotificationResource;
use App\Models\AppNotification;
use App\Models\Subject;
use App\Models\User;
use App\Services\PlatformAuditService;
use App\Services\PlatformNotificationService;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Validation\ValidationException;

class CreateNotification extends CreateRecord
{
    protected static string $resource = NotificationResource::class;

    private int $recipientCount = 0;

    protected function handleRecordCreation(array $data): Model
    {
        $audience = $data['audience'] ?? NotificationResource::AUDIENCE_USER;
        $type = $data['type'] ?? AppNotificationType::Custom->value;
        $payload = $this->targetData($data);
        $service = app(PlatformNotificationService::class);
        $single = $audience === NotificationResource::AUDIENCE_USER;

        $first = null;
        $count = 0;

        $this->recipients($audience, $data)->chunkById(200, function ($users) use (
            $service, $data, $type, $payload, $single, &$first, &$count,
        ): void {
            foreach ($users as $user) {
                $notification = $service->deliverAdminNotification(
                    user: $user,
                    title: $data['title'],
                    body: $data['body'],
                    type: $type,
                    isRead: (bool) ($data['is_read'] ?? false),
                    data: $payload,
                    // Email goes out synchronously; keep it to one recipient.
                    sendEmail: $single,
                );
                $first ??= $notification;
                $count++;
            }
        });

        if (! $first instanceof AppNotification) {
            throw ValidationException::withMessages([
                'data.audience' => 'لا يوجد طلاب مطابقون لهذا الاختيار.',
            ]);
        }

        $this->recipientCount = $count;

        app(PlatformAuditService::class)->logAdmin(
            action: 'notification.created',
            actor: auth()->user(),
            description: $count === 1
                ? 'تم إرسال إشعار «'.$first->title.'» إلى «'.$first->user?->name.'».'
                : 'تم إرسال إشعار «'.$first->title.'» إلى '.$count.' طالب ('.$this->audienceLabel($audience, $data).').',
            model: $first,
        );

        return $first;
    }

    /**
     * @param  array<string, mixed>  $data
     * @return Builder<User>
     */
    private function recipients(string $audience, array $data): Builder
    {
        $students = User::query()
            ->where('role', UserRole::Student)
            ->where('status', UserStatus::Active);

        return match ($audience) {
            NotificationResource::AUDIENCE_STUDENTS => $students
                ->whereKey(array_map('intval', (array) ($data['student_ids'] ?? []))),
            NotificationResource::AUDIENCE_SUBJECT => $students
                ->whereHas('enrolledSubjects', fn (Builder $query) => $query
                    ->where('subjects.id', (int) ($data['audience_subject_id'] ?? 0))
                    ->where('subject_students.payment_status', PaymentStatus::Paid)
                    ->where('subject_students.access_status', AccessStatus::Active)),
            NotificationResource::AUDIENCE_ALL_STUDENTS => $students,
            default => User::query()->whereKey((int) ($data['user_id'] ?? 0)),
        };
    }

    /**
     * The ids the app needs to open the right page on tap.
     *
     * @param  array<string, mixed>  $data
     * @return array<string, int>|null
     */
    private function targetData(array $data): ?array
    {
        $map = [
            'subject_id' => $data['target_subject_id'] ?? null,
            'lesson_id' => $data['target_lesson_id'] ?? null,
            'assignment_id' => $data['target_assignment_id'] ?? null,
            'quiz_id' => $data['target_quiz_id'] ?? null,
            'announcement_id' => $data['target_announcement_id'] ?? null,
        ];

        $clean = array_map('intval', array_filter($map, fn ($value): bool => filled($value)));

        return $clean === [] ? null : $clean;
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private function audienceLabel(string $audience, array $data): string
    {
        return match ($audience) {
            NotificationResource::AUDIENCE_STUDENTS => 'طلاب محددون',
            NotificationResource::AUDIENCE_SUBJECT => 'طلاب مادة «'
                .(Subject::query()->whereKey((int) ($data['audience_subject_id'] ?? 0))->value('title') ?? '—').'»',
            NotificationResource::AUDIENCE_ALL_STUDENTS => 'جميع الطلاب',
            default => 'مستخدم واحد',
        };
    }

    protected function getRedirectUrl(): string
    {
        return $this->recipientCount > 1
            ? static::getResource()::getUrl('index')
            : parent::getRedirectUrl();
    }

    protected function getCreatedNotificationTitle(): ?string
    {
        return $this->recipientCount > 1
            ? 'تم إرسال الإشعار إلى '.$this->recipientCount.' طالب'
            : 'تم إرسال الإشعار';
    }
}
