<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class LessonResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'subject_id' => $this->subject_id,
            'title' => $this->title,
            'description' => $this->description,
            'order' => $this->order,
            'status' => $this->status?->value,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'subject' => SubjectResource::make($this->whenLoaded('subject')),
            'videos' => VideoResource::collection($this->whenLoaded('videos')),
            'files' => LessonFileResource::collection($this->whenLoaded('files')),
            'assignments' => AssignmentResource::collection($this->whenLoaded('assignments')),
            'quizzes' => $this->whenLoaded('quizzes', fn () => $this->quizzes->map(
                fn ($quiz) => (new QuizResource($quiz, hideCorrectAnswers: true))->resolve(),
            )),
        ];
    }
}
