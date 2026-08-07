<?php

namespace App\Services;

use App\Models\User;
use App\Models\Video;
use App\Models\VideoWatchProgress;
use Illuminate\Validation\ValidationException;

class ProgressService
{
    public function updateVideoProgress(User $student, Video $video, array $data): VideoWatchProgress
    {
        $watchedSeconds = max(0, (int) ($data['watched_seconds'] ?? 0));
        $currentPosition = max(0, (int) ($data['current_position'] ?? 0));

        [$watchedSeconds, $currentPosition] = $this->clampProgressValues(
            $video,
            $watchedSeconds,
            $currentPosition,
        );

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
            $attributes['replay_count'] = max(0, (int) $data['replay_count']);
        }

        return VideoWatchProgress::query()->updateOrCreate(
            [
                'student_id' => $student->id,
                'video_id' => $video->id,
            ],
            $attributes,
        );
    }

    /**
     * @return array{0: int, 1: int}
     */
    public function clampProgressValues(Video $video, int $watchedSeconds, int $currentPosition): array
    {
        $duration = (int) ($video->duration_seconds ?? 0);

        if ($duration <= 0) {
            return [$watchedSeconds, $currentPosition];
        }

        $tolerance = max(0, (int) config('video.progress_position_tolerance_seconds', 30));
        $maxAllowed = $duration + $tolerance;

        if ($currentPosition > $maxAllowed || $watchedSeconds > $maxAllowed) {
            throw ValidationException::withMessages([
                'current_position' => ['قيمة التقدم خارج النطاق المسموح للفيديو.'],
            ]);
        }

        return [
            min($watchedSeconds, $maxAllowed),
            min($currentPosition, $maxAllowed),
        ];
    }

    public function calculateCompletionPercentage(int $watchedSeconds, ?int $durationSeconds): float
    {
        if ($durationSeconds === null || $durationSeconds <= 0) {
            return 0.0;
        }

        return min(100.0, ($watchedSeconds / $durationSeconds) * 100);
    }
}
