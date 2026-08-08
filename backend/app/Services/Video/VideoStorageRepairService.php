<?php

namespace App\Services\Video;

use App\Enums\VideoStatus;
use App\Models\Video;
use Illuminate\Support\Facades\Storage;

class VideoStorageRepairService
{
    /**
     * @return array<string, mixed>
     */
    public function repair(bool $dryRun = false): array
    {
        $changes = [];

        foreach (Video::query()->orderBy('id')->get() as $video) {
            $videoChanges = $this->repairVideo($video, $dryRun);
            if ($videoChanges !== []) {
                $changes[] = $videoChanges;
            }
        }

        return [
            'dry_run' => $dryRun,
            'changes' => $changes,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    protected function repairVideo(Video $video, bool $dryRun): array
    {
        $actions = [];

        $fileSizeAction = $this->reconcileFileSize($video, $dryRun);
        if ($fileSizeAction !== null) {
            $actions[] = $fileSizeAction;
        }

        $missingSourceAction = $this->markUnrecoverableMissingSource($video, $dryRun);
        if ($missingSourceAction !== null) {
            $actions[] = $missingSourceAction;
        }

        $orphanReadyAction = $this->markEmptyReadyWithoutSourceAsFailed($video, $dryRun);
        if ($orphanReadyAction !== null) {
            $actions[] = $orphanReadyAction;
        }

        if ($actions === []) {
            return [];
        }

        return [
            'video_id' => $video->id,
            'title' => $video->title,
            'actions' => $actions,
        ];
    }

    /**
     * @return array<string, mixed>|null
     */
    protected function reconcileFileSize(Video $video, bool $dryRun): ?array
    {
        if (! $video->hasLocalStoredFile()) {
            return null;
        }

        $disk = Storage::disk(Video::storageDiskName());
        $actualSize = (int) $disk->size((string) $video->video_path);

        if ($actualSize <= 0 || $video->file_size === $actualSize) {
            return null;
        }

        if (! $dryRun) {
            $video->update(['file_size' => $actualSize]);
        }

        return [
            'type' => 'reconcile_file_size',
            'from' => $video->file_size,
            'to' => $actualSize,
        ];
    }

    /**
     * @return array<string, mixed>|null
     */
    protected function markUnrecoverableMissingSource(Video $video, bool $dryRun): ?array
    {
        if ($video->video_path === null || $video->video_path === '') {
            return null;
        }

        if ($video->hasLocalStoredFile()) {
            return null;
        }

        if ($video->status === VideoStatus::Failed) {
            return null;
        }

        if (! $dryRun) {
            $video->update(['status' => VideoStatus::Failed]);
        }

        return [
            'type' => 'mark_missing_source_failed',
            'from_status' => $video->status->value,
            'to_status' => VideoStatus::Failed->value,
        ];
    }

    /**
     * @return array<string, mixed>|null
     */
    protected function markEmptyReadyWithoutSourceAsFailed(Video $video, bool $dryRun): ?array
    {
        if ($video->status !== VideoStatus::Ready) {
            return null;
        }

        if ($video->hasLocalStoredFile() || filled($video->external_video_id)) {
            return null;
        }

        if ($video->resolvedExternalVideoUrl() !== null) {
            return null;
        }

        if ($video->video_path !== null && $video->video_path !== '') {
            return null;
        }

        if (! $dryRun) {
            $video->update(['status' => VideoStatus::Failed]);
        }

        return [
            'type' => 'mark_empty_ready_failed',
            'from_status' => $video->status->value,
            'to_status' => VideoStatus::Failed->value,
        ];
    }
}
