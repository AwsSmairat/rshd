<?php

namespace App\Services\Bunny;

use App\Enums\VideoStatus;
use App\Jobs\SyncBunnyVideoStatusJob;
use App\Models\Video;
use App\Services\Video\BunnyStreamVideoProvider;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use RuntimeException;

class BunnyStreamService
{
    public function __construct(
        protected BunnyStreamApiClient $api,
        protected BunnyStreamStatusMapper $statusMapper,
    ) {}

    public function isConfigured(): bool
    {
        return $this->api->isConfigured()
            && app(BunnyStreamVideoProvider::class)->isConfigured();
    }

    public function shouldUploadLocalVideo(Video $video): bool
    {
        $externalId = trim((string) ($video->external_video_id ?? ''));

        if ($externalId === '') {
            return true;
        }

        // Check Bunny before retrying an upload with an existing GUID.
        $remote = $this->api->getVideo($externalId);

        $remoteStatus = (int) ($remote['status'] ?? -1);
        $remoteSize = (int) ($remote['storageSize'] ?? 0);

        if ($this->statusMapper->isPlayableApiStatus($remoteStatus)) {
            // A playable remote video must never be uploaded again.
            $this->applyRemotePayload($video, $remote);

            return false;
        }

        if ($remoteSize > 0) {
            // Partial data and processing data cannot be distinguished
            // safely by storageSize alone.
            throw new RuntimeException(
                'Ambiguous Bunny upload state: remote data exists, but completion is unconfirmed.'
            );
        }

        return true;
    }

    public function uploadLocalVideo(Video $video): void
    {
        if (! $this->api->isConfigured()) {
            throw new RuntimeException('Bunny Stream API is not configured.');
        }

        if ($video->video_path === null || $video->video_path === '') {
            throw new RuntimeException('Local staging file is missing for Bunny upload.');
        }

        $disk = Storage::disk(Video::storageDiskName());

        if (! $disk->exists($video->video_path)) {
            throw new RuntimeException('Local staging file was not found.');
        }

        $video->update([
            'status' => VideoStatus::Uploading,
            'storage_provider' => 'bunny',
        ]);

        $externalId = trim((string) ($video->external_video_id ?? ''));

        if ($externalId === '') {
            $created = $this->api->createVideo($video->title);
            $externalId = (string) ($created['guid'] ?? '');

            if ($externalId === '') {
                throw new RuntimeException('Bunny Stream did not return a video id.');
            }

            $video->update([
                'external_video_id' => $externalId,
                'status' => VideoStatus::Processing,
            ]);
        } else {
            // Resume the existing Bunny asset instead of creating a duplicate.
            $video->update(['status' => VideoStatus::Processing]);
        }

        $stream = $disk->readStream($video->video_path);

        if ($stream === false) {
            throw new RuntimeException('Unable to read local staging file for Bunny upload.');
        }

        try {
            $this->api->uploadVideo($externalId, $stream);
        } finally {
            if (is_resource($stream)) {
                fclose($stream);
            }
        }

        Log::info('bunny.stream.upload.completed', [
            'video_id' => $video->id,
            'external_video_id' => $externalId,
        ]);
    }

    public function syncVideoStatus(Video $video): Video
    {
        if ($video->external_video_id === null || $video->external_video_id === '') {
            return $video;
        }

        $payload = $this->api->getVideo($video->external_video_id);
        $this->applyRemotePayload($video, $payload);

        return $video->fresh() ?? $video;
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function applyRemotePayload(Video $video, array $payload): void
    {
        $remoteStatus = (int) ($payload['status'] ?? -1);
        $mappedStatus = $this->statusMapper->fromApiStatus($remoteStatus);

        $attributes = [
            'status' => $mappedStatus,
        ];

        $length = (int) ($payload['length'] ?? 0);

        if ($length > 0) {
            $attributes['duration_seconds'] = $length;
        }

        // A verified ready video may still need its duration.
        // Never downgrade its existing ready status.
        if ($mappedStatus === VideoStatus::Ready && $length > 0) {
            Video::query()
                ->whereKey($video->id)
                ->where('external_video_id', $video->external_video_id)
                ->where('status', VideoStatus::Ready->value)
                ->where(function ($query): void {
                    $query->whereNull('duration_seconds')
                        ->orWhere('duration_seconds', '<=', 0);
                })
                ->update([
                    'duration_seconds' => $length,
                ]);
        }

        $updated = Video::query()
            ->whereKey($video->id)
            ->where('external_video_id', $video->external_video_id)
            ->whereIn(
                'status',
                $mappedStatus === VideoStatus::Uploading
                    ? ['uploading']
                    : ['uploading', 'processing']
            )
            ->update([
                ...$attributes,
                'status' => $mappedStatus->value,
            ]);

        if ($updated === 0) {
            return;
        }

        $video->refresh();

        Log::info('bunny.stream.status.updated', [
            'video_id' => $video->id,
            'external_video_id' => $video->external_video_id,
            'remote_status' => $remoteStatus,
            'mapped_status' => $mappedStatus->value,
        ]);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function applyWebhookPayload(array $payload): void
    {
        $externalId = (string) ($payload['VideoGuid'] ?? '');
        $remoteStatus = (int) ($payload['Status'] ?? -1);

        if ($externalId === '') {
            return;
        }

        $video = Video::query()
            ->where('external_video_id', $externalId)
            ->first();

        if ($video === null) {
            Log::warning('bunny.stream.webhook.unknown_video', [
                'external_video_id' => $externalId,
                'remote_status' => $remoteStatus,
            ]);

            return;
        }

        $mappedStatus = $this->statusMapper->fromWebhookStatus($remoteStatus);

        Video::query()
            ->whereKey($video->id)
            ->where('external_video_id', $externalId)
            ->whereIn(
                'status',
                $mappedStatus === VideoStatus::Uploading
                    ? ['uploading']
                    : ['uploading', 'processing']
            )
            ->update([
                'status' => $mappedStatus->value,
            ]);

        $video->refresh();

        if ($this->statusMapper->isPlayableWebhookStatus($remoteStatus)) {
            SyncBunnyVideoStatusJob::dispatch($video->id)->delay(now()->addSeconds(5));
        }

        Log::info('bunny.stream.webhook.processed', [
            'video_id' => $video->id,
            'external_video_id' => $externalId,
            'remote_status' => $remoteStatus,
            'mapped_status' => $mappedStatus->value,
        ]);
    }
}
