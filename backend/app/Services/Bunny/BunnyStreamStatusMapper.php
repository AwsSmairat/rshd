<?php

namespace App\Services\Bunny;

use App\Enums\VideoStatus;

class BunnyStreamStatusMapper
{
    /**
     * Map Bunny Stream HTTP API video status codes.
     *
     * @see https://bunny.net/docs/api-reference/stream/manage-videos/get-video
     */
    public function fromApiStatus(int $status): VideoStatus
    {
        return match ($status) {
            0, 1 => VideoStatus::Uploading,
            2, 3, 7, 8 => VideoStatus::Processing,
            4 => VideoStatus::Ready,
            5, 6 => VideoStatus::Failed,
            default => VideoStatus::Processing,
        };
    }

    /**
     * Map Bunny Stream webhook status codes.
     *
     * @see https://bunny.net/docs/stream/webhooks
     */
    public function fromWebhookStatus(int $status): VideoStatus
    {
        return match ($status) {
            6 => VideoStatus::Uploading,
            0, 1, 2 => VideoStatus::Processing,
            3, 4, 9, 10 => VideoStatus::Ready,
            5, 8 => VideoStatus::Failed,
            default => VideoStatus::Processing,
        };
    }

    public function isPlayableApiStatus(int $status): bool
    {
        return $status === 4;
    }

    public function isPlayableWebhookStatus(int $status): bool
    {
        return in_array($status, [3, 4], true);
    }
}
