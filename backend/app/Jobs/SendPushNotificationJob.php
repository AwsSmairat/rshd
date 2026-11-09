<?php

namespace App\Jobs;

use App\Enums\UserStatus;
use App\Models\AppNotification;
use App\Models\PushDeviceToken;
use App\Models\User;
use App\Services\Push\FcmClient;
use App\Services\Push\PushMessageBuilder;
use Illuminate\Contracts\Encryption\DecryptException;
use Illuminate\Contracts\Queue\ShouldBeUnique;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Pushes one notification to every device the user is signed in on.
 *
 * Sent at most once: the job is unique per notification, and the
 * notification is claimed (push_sent_at) before anything goes out, so a
 * duplicated or retried job finds it already sent and stops. Retries only
 * happen when FCM was unreachable for every device, and the claim is
 * released for them.
 */
class SendPushNotificationJob implements ShouldBeUnique, ShouldQueue
{
    use Queueable;

    public int $tries = 4;

    public int $uniqueFor = 600;

    /**
     * @param  array<string, mixed>  $data
     */
    public function __construct(
        public int $userId,
        public string $title,
        public string $body,
        public string $type,
        public array $data = [],
        public ?int $notificationId = null,
    ) {}

    /**
     * @return list<int>
     */
    public function backoff(): array
    {
        return [30, 120, 600];
    }

    public function uniqueId(): string
    {
        return $this->notificationId !== null
            ? 'n:'.$this->notificationId
            : 'u:'.$this->userId.':'.hash('sha256', $this->type.$this->title.$this->body);
    }

    public function handle(FcmClient $fcm, PushMessageBuilder $builder): void
    {
        $user = User::query()->find($this->userId);
        if ($user === null || $user->status === UserStatus::Blocked) {
            return;
        }

        if (! $fcm->isConfigured()) {
            Log::warning('Push skipped: Firebase credentials are not configured on the server.');

            return;
        }

        if (! $this->claim()) {
            return;
        }

        $devices = PushDeviceToken::query()
            ->where('user_id', $user->id)
            ->whereHas('accessToken')
            ->get();

        $sent = 0;
        $transient = 0;

        foreach ($devices as $device) {
            try {
                $message = $builder->build(
                    $device,
                    $user,
                    $this->title,
                    $this->body,
                    $this->type,
                    $this->data,
                    $this->notificationId,
                );
            } catch (DecryptException) {
                // Stored under a previous APP_KEY; the app registers again.
                $device->delete();

                continue;
            }

            try {
                $result = $fcm->send($message);
            } catch (Throwable $error) {
                Log::warning('Push send failed', ['error' => $error->getMessage()]);
                $transient++;

                continue;
            }

            if ($result->successful()) {
                $sent++;
            } elseif ($result->tokenIsDead()) {
                $device->delete();
            } elseif ($result->isTransient()) {
                $transient++;
            } else {
                Log::warning('Push rejected by FCM', [
                    'status' => $result->status,
                    'error' => $result->errorCode,
                    'platform' => $device->platform,
                ]);
            }
        }

        if ($sent === 0 && $transient > 0 && $this->attempts() < $this->tries) {
            $this->releaseClaim();
            $this->release($this->backoff()[min($this->attempts() - 1, 2)]);
        }
    }

    /**
     * Marks the notification as pushed; false when another run already did.
     */
    private function claim(): bool
    {
        if ($this->notificationId === null) {
            return true;
        }

        return AppNotification::query()
            ->whereKey($this->notificationId)
            ->whereNull('push_sent_at')
            ->update(['push_sent_at' => now()]) === 1;
    }

    private function releaseClaim(): void
    {
        if ($this->notificationId === null) {
            return;
        }

        AppNotification::query()
            ->whereKey($this->notificationId)
            ->update(['push_sent_at' => null]);
    }
}
