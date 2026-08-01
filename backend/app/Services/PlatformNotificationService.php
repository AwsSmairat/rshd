<?php

namespace App\Services;

use App\Enums\UserRole;
use App\Mail\PlatformNotificationMail;
use App\Models\AppNotification;
use App\Models\User;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class PlatformNotificationService
{
    public function __construct(
        protected PlatformSettingsService $settings,
    ) {}

    public function notifyUser(
        User $user,
        string $title,
        string $body,
        string $type,
        string $settingKey,
        ?string $userPreferenceKey = null,
        ?array $data = null,
    ): void {
        if (! $this->settings->enabled($settingKey, 'notifications')) {
            return;
        }

        if ($userPreferenceKey !== null && ! $user->prefersNotification($userPreferenceKey)) {
            return;
        }

        if ($this->settings->enabled('in_app_notifications_enabled', 'notifications')) {
            AppNotification::query()->create([
                'user_id' => $user->id,
                'title' => $title,
                'body' => $body,
                'type' => $type,
                'data' => $data,
                'is_read' => false,
            ]);
        }

        $this->sendEmailNotification($user, $title, $body);
        $this->queuePushNotification($user, $title, $body, $type);
    }

    public function notifyAdmins(
        string $title,
        string $body,
        string $type,
        string $settingKey,
    ): void {
        if (! $this->settings->enabled($settingKey, 'notifications')) {
            return;
        }

        User::query()
            ->where('role', UserRole::Admin)
            ->each(function (User $admin) use ($title, $body, $type): void {
                if ($this->settings->enabled('in_app_notifications_enabled', 'notifications')) {
                    AppNotification::query()->create([
                        'user_id' => $admin->id,
                        'title' => $title,
                        'body' => $body,
                        'type' => $type,
                        'is_read' => false,
                    ]);
                }

                $this->sendEmailNotification($admin, $title, $body);
                $this->queuePushNotification($admin, $title, $body, $type);
            });
    }

    protected function sendEmailNotification(User $user, string $title, string $body): void
    {
        if (! $this->settings->enabled('email_notifications_enabled', 'notifications')) {
            return;
        }

        if ($user->email === null || $user->email === '') {
            return;
        }

        $this->settings->applyMailPreferences();
        Mail::to($user->email)->send(new PlatformNotificationMail($user, $title, $body));
    }

    protected function queuePushNotification(User $user, string $title, string $body, string $type): void
    {
        if (! $this->settings->enabled('push_notifications_enabled', 'notifications')) {
            return;
        }

        Log::info('Platform push notification queued', [
            'user_id' => $user->id,
            'title' => $title,
            'body' => $body,
            'type' => $type,
        ]);
    }

    public function deliverAdminNotification(
        User $user,
        string $title,
        string $body,
        string $type,
        bool $isRead = false,
    ): AppNotification {
        $notification = AppNotification::query()->create([
            'user_id' => $user->id,
            'title' => $title,
            'body' => $body,
            'type' => $type,
            'is_read' => $isRead,
        ]);

        $this->sendEmailNotification($user, $title, $body);
        $this->queuePushNotification($user, $title, $body, $type);

        return $notification;
    }
}
