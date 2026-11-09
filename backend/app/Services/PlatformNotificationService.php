<?php

namespace App\Services;

use App\Enums\UserRole;
use App\Mail\PlatformNotificationMail;
use App\Models\AppNotification;
use App\Models\User;
use App\Services\Push\PushNotificationService;
use Illuminate\Support\Facades\Mail;

class PlatformNotificationService
{
    public function __construct(
        protected PlatformSettingsService $settings,
        protected PushNotificationService $push,
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

        $notification = null;
        if ($this->settings->enabled('in_app_notifications_enabled', 'notifications')) {
            $notification = AppNotification::query()->create([
                'user_id' => $user->id,
                'title' => $title,
                'body' => $body,
                'type' => $type,
                'data' => $data,
                'is_read' => false,
            ]);
        }

        $this->sendEmailNotification($user, $title, $body);
        $this->queuePushNotification($user, $title, $body, $type, $notification, $data, $userPreferenceKey);
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
                $notification = null;
                if ($this->settings->enabled('in_app_notifications_enabled', 'notifications')) {
                    $notification = AppNotification::query()->create([
                        'user_id' => $admin->id,
                        'title' => $title,
                        'body' => $body,
                        'type' => $type,
                        'is_read' => false,
                    ]);
                }

                $this->sendEmailNotification($admin, $title, $body);
                $this->queuePushNotification($admin, $title, $body, $type, $notification);
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

    /**
     * @param  array<string, mixed>|null  $data
     */
    protected function queuePushNotification(
        User $user,
        string $title,
        string $body,
        string $type,
        ?AppNotification $notification = null,
        ?array $data = null,
        ?string $preferenceKey = null,
    ): bool {
        return $this->push->queue($user, $title, $body, $type, $notification, $data, $preferenceKey);
    }

    /**
     * A notification an admin writes by hand. The in-app copy is always kept;
     * the push respects the student's preference for that type.
     *
     * @param  array<string, mixed>|null  $data
     */
    public function deliverAdminNotification(
        User $user,
        string $title,
        string $body,
        string $type,
        bool $isRead = false,
        ?array $data = null,
        bool $sendEmail = true,
    ): AppNotification {
        $notification = AppNotification::query()->create([
            'user_id' => $user->id,
            'title' => $title,
            'body' => $body,
            'type' => $type,
            'data' => $data === [] ? null : $data,
            'is_read' => $isRead,
        ]);

        if ($sendEmail) {
            $this->sendEmailNotification($user, $title, $body);
        }

        if (! $isRead) {
            $this->queuePushNotification($user, $title, $body, $type, $notification, $data);
        }

        return $notification;
    }
}
