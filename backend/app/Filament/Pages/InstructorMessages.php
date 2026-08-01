<?php

namespace App\Filament\Pages;

use App\Enums\AppNotificationType;
use App\Filament\Concerns\InstructorOnlyPage;
use App\Filament\Resources\AnnouncementResource;
use App\Models\AppNotification;
use App\Models\User;
use App\Services\InstructorMessageService;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Contracts\Support\Htmlable;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;

class InstructorMessages extends Page
{
    use InstructorOnlyPage;

    protected static ?string $navigationIcon = 'heroicon-o-chat-bubble-left-right';

    protected static ?string $navigationGroup = 'التقويم والتواصل';

    protected static ?string $navigationLabel = 'الرسائل';

    protected static ?string $title = 'الرسائل';

    protected static ?int $navigationSort = 1;

    protected static string $view = 'filament.pages.instructor.messages';

    public ?string $loadError = null;

    /** @var Collection<int, AppNotification> */
    public Collection $messages;

    public ?int $replyingToId = null;

    public string $replyBody = '';

    public ?string $replyError = null;

    public function mount(): void
    {
        $this->messages = collect();
        $this->loadMessages();
    }

    public function getTitle(): string|Htmlable
    {
        return 'الرسائل';
    }

    public function getHeading(): string|Htmlable
    {
        return '';
    }

    public function loadMessages(): void
    {
        $user = $this->authUser();

        if ($user === null) {
            $this->messages = collect();

            return;
        }

        try {
            $repliedStudentMessageIds = AppNotification::query()
                ->where('type', AppNotificationType::InstructorReply->value)
                ->get(['data'])
                ->map(fn (AppNotification $notification): ?int => isset($notification->data['in_reply_to_id'])
                    ? (int) $notification->data['in_reply_to_id']
                    : null)
                ->filter(fn (?int $id): bool => $id !== null && $id > 0)
                ->flip();

            $this->messages = AppNotification::query()
                ->where('user_id', $user->id)
                ->latest('created_at')
                ->limit(50)
                ->get()
                ->reject(function (AppNotification $message) use ($repliedStudentMessageIds): bool {
                    if ($message->type !== AppNotificationType::StudentMessage->value) {
                        return false;
                    }

                    if ($repliedStudentMessageIds->has($message->id)) {
                        return true;
                    }

                    $data = is_array($message->data) ? $message->data : [];

                    return ! empty($data['replied_at']);
                })
                ->take(30)
                ->values();
        } catch (\Throwable $exception) {
            report($exception);
            $this->loadError = 'تعذر تحميل الرسائل.';
            $this->messages = collect();
        }
    }

    public function createAnnouncementUrl(): string
    {
        return AnnouncementResource::getUrl('create');
    }

    public function unreadCount(): int
    {
        return $this->messages->where('is_read', false)->count();
    }

    public function startReply(int $messageId): void
    {
        $message = $this->findOwnedMessage($messageId);

        if ($message === null || ! $this->canReplyTo($message)) {
            $this->replyError = 'لا يمكن الرد على هذه الرسالة.';

            return;
        }

        $this->replyingToId = $message->id;
        $this->replyBody = '';
        $this->replyError = null;
    }

    public function cancelReply(): void
    {
        $this->replyingToId = null;
        $this->replyBody = '';
        $this->replyError = null;
    }

    public function sendReply(InstructorMessageService $messageService): void
    {
        $this->replyError = null;

        $user = $this->authUser();

        if ($user === null || $this->replyingToId === null) {
            return;
        }

        $message = $this->findOwnedMessage($this->replyingToId);

        if ($message === null || ! $this->canReplyTo($message)) {
            $this->replyError = 'لا يمكن الرد على هذه الرسالة.';

            return;
        }

        try {
            $messageService->replyToStudentMessage(
                $user,
                $message,
                $this->replyBody,
            );
        } catch (ValidationException $exception) {
            $this->replyError = collect($exception->errors())->flatten()->first()
                ?? 'تعذر إرسال الرد.';

            return;
        } catch (\Throwable $exception) {
            report($exception);
            $this->replyError = 'تعذر إرسال الرد.';

            return;
        }

        $this->cancelReply();
        $this->loadMessages();

        Notification::make()
            ->title('تم الرد')
            ->body('وصل ردك إلى الطالب في الإشعارات.')
            ->success()
            ->send();
    }

    public function canReplyTo(AppNotification $message): bool
    {
        return $message->type === AppNotificationType::StudentMessage->value
            && ! $this->hasBeenReplied($message);
    }

    public function hasBeenReplied(AppNotification $message): bool
    {
        $data = is_array($message->data) ? $message->data : [];

        if (! empty($data['replied_at'])) {
            return true;
        }

        return AppNotification::query()
            ->where('type', AppNotificationType::InstructorReply->value)
            ->where('data->in_reply_to_id', $message->id)
            ->exists();
    }

    /**
     * @return array<string, mixed>
     */
    public function messageMeta(AppNotification $message): array
    {
        $data = is_array($message->data) ? $message->data : [];

        return [
            'student_name' => $data['student_name'] ?? null,
            'subject_title' => $data['subject_title'] ?? null,
        ];
    }

    protected function findOwnedMessage(int $messageId): ?AppNotification
    {
        $user = $this->authUser();

        if ($user === null) {
            return null;
        }

        return AppNotification::query()
            ->whereKey($messageId)
            ->where('user_id', $user->id)
            ->first();
    }

    protected function authUser(): ?User
    {
        /** @var User|null */
        return Auth::user();
    }
}
