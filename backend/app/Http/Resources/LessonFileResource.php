<?php

namespace App\Http\Resources;

use App\Models\User;
use App\Services\EnrollmentService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class LessonFileResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $canOpen = $this->viewerCanOpen($request->user());

        return [
            'id' => $this->id,
            'lesson_id' => $this->lesson_id,
            'title' => $this->title,
            'file_type' => $this->file_type?->value,
            'file_url' => $canOpen ? $this->resolvedFileUrl() : null,
            'original_file_name' => $this->original_file_name,
            'is_locked' => ! $canOpen,
            'file_size' => $this->file_size,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'lesson' => LessonResource::make($this->whenLoaded('lesson')),
        ];
    }

    protected function viewerCanOpen(?User $user): bool
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

        if ($user->isStudent() && $this->lesson?->subject !== null) {
            return app(EnrollmentService::class)
                ->checkStudentAccessToSubject($user, $this->lesson->subject);
        }

        return false;
    }
}
