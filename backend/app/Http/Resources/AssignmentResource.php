<?php

namespace App\Http\Resources;

use App\Models\User;
use App\Services\EnrollmentService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AssignmentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        // Lessons are previewable without enrollment, so the attachment URL —
        // which points at a permanently public disk — must be gated here.
        $canAccess = $this->viewerCanAccess($request->user());

        return [
            'id' => $this->id,
            'subject_id' => $this->subject_id,
            'lesson_id' => $this->lesson_id,
            'title' => $this->title,
            'description' => $this->description,
            'attachment_url' => $canAccess ? $this->resolvedAttachmentUrl() : null,
            'is_locked' => ! $canAccess,
            'original_file_name' => $this->original_file_name,
            'file_size' => $this->file_size,
            'file_mime_type' => $this->file_mime_type,
            'due_date' => $this->due_date,
            'status' => $this->status?->value,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'subject' => SubjectResource::make($this->whenLoaded('subject')),
            'lesson' => LessonResource::make($this->whenLoaded('lesson')),
            'submission' => $this->when(
                $this->relationLoaded('submissions'),
                fn () => $this->submissions->first()
                    ? AssignmentSubmissionResource::make($this->submissions->first())
                    : null,
            ),
            'submissions' => $this->when(
                $this->relationLoaded('submissions'),
                fn () => AssignmentSubmissionResource::collection($this->submissions),
            ),
        ];
    }

    protected function viewerCanAccess(?User $user): bool
    {
        if ($user === null) {
            return false;
        }

        if ($user->isAdmin()) {
            return true;
        }

        $this->resource->loadMissing('subject');

        if ($user->isInstructor() && $this->subject?->instructor_id === $user->id) {
            return true;
        }

        if ($user->isStudent() && $this->subject !== null) {
            return app(EnrollmentService::class)
                ->checkStudentAccessToSubject($user, $this->subject);
        }

        return false;
    }
}
