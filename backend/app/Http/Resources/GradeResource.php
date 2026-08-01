<?php

namespace App\Http\Resources;

use App\Enums\GradeSourceType;
use App\Models\Assignment;
use App\Models\Quiz;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class GradeResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'student_id' => $this->student_id,
            'subject_id' => $this->subject_id,
            'source_type' => $this->source_type?->value,
            'source_id' => $this->source_id,
            'grade' => $this->grade,
            'notes' => $this->notes,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'subject' => SubjectResource::make($this->whenLoaded('subject')),
            'student' => UserResource::make($this->whenLoaded('student')),
            'source_title' => $this->resolveSourceTitle(),
        ];
    }

    private function resolveSourceTitle(): ?string
    {
        if ($this->source_id === null) {
            return null;
        }

        return match ($this->source_type) {
            GradeSourceType::Quiz => Quiz::query()->whereKey($this->source_id)->value('title'),
            GradeSourceType::Assignment => Assignment::query()->whereKey($this->source_id)->value('title'),
            GradeSourceType::Manual => null,
        };
    }
}
