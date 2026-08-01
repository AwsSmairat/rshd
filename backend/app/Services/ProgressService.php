<?php

namespace App\Services;

use App\Models\User;
use App\Models\Video;
use App\Models\VideoWatchProgress;

class ProgressService
{
    public function updateVideoProgress(User $student, Video $video, array $data): VideoWatchProgress
    {
        $watchedSeconds = (int) ($data['watched_seconds'] ?? 0);
        $currentPosition = (int) ($data['current_position'] ?? 0);

        $attributes = [
            'watched_seconds' => $watchedSeconds,
            'current_position' => $currentPosition,
            'completion_percentage' => $this->calculateCompletionPercentage(
                $watchedSeconds,
                $video->duration_seconds,
            ),
            'last_watched_at' => now(),
        ];

        if (array_key_exists('replay_count', $data)) {
            $attributes['replay_count'] = (int) $data['replay_count'];
        }

        return VideoWatchProgress::query()->updateOrCreate(
            [
                'student_id' => $student->id,
                'video_id' => $video->id,
            ],
            $attributes,
        );
    }

    public function calculateCompletionPercentage(int $watchedSeconds, ?int $durationSeconds): float
    {
        if ($durationSeconds === null || $durationSeconds <= 0) {
            return 0.0;
        }

        return min(100.0, ($watchedSeconds / $durationSeconds) * 100);
    }
}
