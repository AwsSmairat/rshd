<?php

namespace App\Http\Resources;

use App\Models\User;
use App\Services\EnrollmentService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class VideoResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $canPlay = $this->viewerCanPlay($request->user());

        return [
            'id' => $this->id,
            'lesson_id' => $this->lesson_id,
            'title' => $this->title,
            'storage_provider' => $this->storage_provider,
            'video_url' => $canPlay ? $this->resolvedVideoUrl() : null,
            'is_free' => (bool) $this->is_free,
            'is_locked' => ! $canPlay,
            'original_file_name' => $this->original_file_name,
            'file_size' => $this->file_size,
            'duration_seconds' => $this->duration_seconds,
            'status' => $this->status?->value,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'lesson' => LessonResource::make($this->whenLoaded('lesson')),
            'progress' => $this->when(
                $canPlay && $this->relationLoaded('progress'),
                fn () => $this->progress->first()?->only([
                    'watched_seconds',
                    'current_position',
                    'completion_percentage',
                    'replay_count',
                    'last_watched_at',
                ]),
            ),
        ];
    }

    protected function viewerCanPlay(?User $user): bool
    {
        if ($user === null) {
            return false;
        }

        if ($user->isAdmin()) {
            return true;
        }

        $this->resource->loadMissing('lesson.subject');

        if ($user->isInstructor()
            && $this->lesson?->subject?->instructor_id === $user->id) {
            return true;
        }

        if ((bool) $this->is_free) {
            return true;
        }

        if ($user->isStudent() && $this->lesson?->subject !== null) {
            return app(EnrollmentService::class)
                ->checkStudentAccessToSubject($user, $this->lesson->subject);
        }

        return false;
    }
}
