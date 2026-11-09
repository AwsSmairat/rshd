<?php

namespace App\Services\Push;

use App\Models\PushDeviceToken;
use App\Models\User;
use Illuminate\Support\Str;

/**
 * Builds the FCM v1 message for one device.
 *
 * The data block carries what the app needs to open the right screen on
 * tap — the notification id, its type, its target ids and the account it
 * belongs to — all as strings, as FCM requires.
 */
class PushMessageBuilder
{
    public const ANDROID_CHANNEL = 'rshd_general';

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    public function build(
        PushDeviceToken $device,
        User $user,
        string $title,
        string $body,
        string $type,
        array $data,
        ?int $notificationId,
    ): array {
        $collapseId = $notificationId !== null
            ? 'rshd-n-'.$notificationId
            : 'rshd-'.substr(hash('sha256', $type.$title.$body), 0, 32);
        $sound = (bool) $user->preference('notification_sound', true);

        $title = Str::limit($title, 120, '…');
        $body = Str::limit($body, 400, '…');

        $payload = [
            'user_id' => (string) $user->id,
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'rshd_data' => json_encode($this->scalarData($data), JSON_UNESCAPED_UNICODE) ?: '{}',
        ];
        if ($notificationId !== null) {
            $payload['notification_id'] = (string) $notificationId;
        }

        $android = [
            'priority' => 'HIGH',
            // A retried send replaces the earlier copy instead of stacking.
            'collapse_key' => $collapseId,
            'notification' => array_filter([
                'channel_id' => self::ANDROID_CHANNEL,
                'tag' => $collapseId,
                'default_sound' => $sound ?: null,
            ], fn ($value) => $value !== null),
        ];

        $aps = [
            'thread-id' => $type,
        ];
        if ($sound) {
            $aps['sound'] = 'default';
        }

        return [
            'token' => $device->token,
            'notification' => [
                'title' => $title,
                'body' => $body,
            ],
            'data' => $payload,
            'android' => $android,
            'apns' => [
                'headers' => [
                    'apns-priority' => '10',
                    'apns-push-type' => 'alert',
                    'apns-collapse-id' => $collapseId,
                ],
                'payload' => [
                    'aps' => $aps,
                ],
            ],
        ];
    }

    /**
     * Only plain values travel in the payload (ids, short strings).
     *
     * @param  array<string, mixed>  $data
     * @return array<string, scalar>
     */
    private function scalarData(array $data): array
    {
        $clean = [];
        foreach ($data as $key => $value) {
            if (is_int($value) || is_float($value) || is_bool($value)) {
                $clean[(string) $key] = $value;
            } elseif (is_string($value) && mb_strlen($value) <= 200) {
                $clean[(string) $key] = $value;
            }
        }

        return $clean;
    }
}
