<?php

namespace App\Filament\Resources\NotificationResource\Pages;

use App\Enums\AppNotificationType;
use App\Filament\Resources\NotificationResource;
use App\Models\User;
use App\Services\PlatformAuditService;
use App\Services\PlatformNotificationService;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Database\Eloquent\Model;

class CreateNotification extends CreateRecord
{
    protected static string $resource = NotificationResource::class;

    protected function handleRecordCreation(array $data): Model
    {
        /** @var User $user */
        $user = User::query()->findOrFail($data['user_id']);

        $notification = app(PlatformNotificationService::class)->deliverAdminNotification(
            user: $user,
            title: $data['title'],
            body: $data['body'],
            type: $data['type'] ?? AppNotificationType::Custom->value,
            isRead: (bool) ($data['is_read'] ?? false),
        );

        app(PlatformAuditService::class)->logAdmin(
            action: 'notification.created',
            actor: auth()->user(),
            description: 'تم إرسال إشعار «'.$notification->title.'» إلى «'.$user->name.'».',
            model: $notification,
        );

        return $notification;
    }

    protected function getCreatedNotificationTitle(): ?string
    {
        return 'تم إرسال الإشعار';
    }
}
