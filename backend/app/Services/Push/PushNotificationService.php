<?php

namespace App\Services\Push;

use App\Enums\UserStatus;
use App\Jobs\SendPushNotificationJob;
use App\Models\AppNotification;
use App\Models\PushDeviceToken;
use App\Models\User;
use App\Services\PlatformSettingsService;
use Illuminate\Support\Facades\Log;
use Laravel\Sanctum\PersonalAccessToken;
use Throwable;

/**
 * Hands notifications to Firebase Cloud Messaging.
 *
 * The in-app notification is always written first by the caller; push is a
 * best-effort extra on top of it, sent from the queue, so a push that fails
 * never loses the notification and never slows the request that caused it.
 */
class PushNotificationService
{
    /**
     * The student preference that controls push for each notification type.
     * Types missing here (subject activation, for example) are always pushed.
     */
    private const PREFERENCE_FOR_TYPE = [
        'lesson_published' => 'notify_lessons',
        'assignment_created' => 'notify_assignments',
        'assignment_reminder' => 'notify_assignment_reminders',
        'quiz_created' => 'notify_quizzes',
        'quiz_reminder' => 'notify_quiz_reminders',
        'grade_published' => 'notify_grades',
        'announcement' => 'notify_announcements',
        'instructor_reply' => 'notify_messages',
        'student_message' => 'notify_messages',
        'custom' => 'notify_platform_updates',
    ];

    public function __construct(
        protected PlatformSettingsService $settings,
    ) {}

    public function enabled(): bool
    {
        return $this->settings->enabled('push_notifications_enabled', 'notifications');
    }

    public static function preferenceKeyFor(string $type): ?string
    {
        return self::PREFERENCE_FOR_TYPE[$type] ?? null;
    }

    /**
     * Queues a push for one user. Returns whether a push was queued.
     *
     * @param  array<string, mixed>|null  $data
     */
    public function queue(
        User $user,
        string $title,
        string $body,
        string $type,
        ?AppNotification $notification = null,
        ?array $data = null,
        ?string $preferenceKey = null,
    ): bool {
        try {
            if (! $this->enabled() || $user->status === UserStatus::Blocked) {
                return false;
            }

            $preferenceKey ??= self::preferenceKeyFor($type);
            if ($preferenceKey !== null && ! $user->prefersNotification($preferenceKey)) {
                return false;
            }

            if (! $user->pushDeviceTokens()->exists()) {
                return false;
            }

            SendPushNotificationJob::dispatch(
                userId: $user->id,
                title: $title,
                body: $body,
                type: $type,
                data: $data ?? ($notification?->data ?? []),
                notificationId: $notification?->id,
            )->onQueue((string) config('services.firebase.push_queue', 'default'));

            return true;
        } catch (Throwable $error) {
            // Push must never break the action that produced the notification.
            Log::warning('Push notification could not be queued', [
                'user_id' => $user->id,
                'type' => $type,
                'error' => $error->getMessage(),
            ]);

            return false;
        }
    }

    /**
     * Binds an FCM token to the signed-in session. A token belongs to one
     * install, so registering it moves it away from any previous account.
     */
    public function register(
        User $user,
        PersonalAccessToken $session,
        string $token,
        string $platform,
        ?string $deviceId,
        ?string $appVersion,
    ): PushDeviceToken {
        $hash = PushDeviceToken::hashToken($token);

        // The same session refreshing to a new token: drop the old one.
        PushDeviceToken::query()
            ->where('personal_access_token_id', $session->getKey())
            ->where('token_hash', '!=', $hash)
            ->delete();

        return PushDeviceToken::query()->updateOrCreate(
            ['token_hash' => $hash],
            [
                'user_id' => $user->id,
                'personal_access_token_id' => $session->getKey(),
                'token' => $token,
                'platform' => $platform,
                'device_id' => $deviceId,
                'app_version' => $appVersion,
                'last_registered_at' => now(),
            ],
        );
    }

    public function unregister(User $user, string $token): int
    {
        return PushDeviceToken::query()
            ->where('user_id', $user->id)
            ->where('token_hash', PushDeviceToken::hashToken($token))
            ->delete();
    }
}
