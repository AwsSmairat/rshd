<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class QuizResource extends JsonResource
{
    public function __construct($resource, public bool $hideCorrectAnswers = false)
    {
        parent::__construct($resource);
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'subject_id' => $this->subject_id,
            'lesson_id' => $this->lesson_id,
            'title' => $this->title,
            'description' => $this->description,
            'duration_minutes' => $this->duration_minutes,
            'status' => $this->status?->value,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'subject' => SubjectResource::make($this->whenLoaded('subject')),
            'lesson' => LessonResource::make($this->whenLoaded('lesson')),
            'questions_count' => $this->whenCounted('questions'),
            'latest_attempt' => $this->when(
                $this->relationLoaded('attempts'),
                fn () => $this->attempts->first()
                    ? QuizAttemptResource::make($this->attempts->first())
                    : null,
            ),
            'questions' => $this->whenLoaded('questions', fn () => $this->questions->map(
                fn ($question) => [
                    'id' => $question->id,
                    'question_text' => $question->question_text,
                    'question_type' => $question->question_type?->value,
                    'points' => $question->points,
                    'answers' => $question->relationLoaded('answers')
                        ? $question->answers->map(fn ($answer) => array_filter([
                            'id' => $answer->id,
                            'answer_text' => $answer->answer_text,
                            'is_correct' => $this->hideCorrectAnswers ? null : $answer->is_correct,
                        ], fn ($value) => $value !== null))
                        : [],
                ],
            )),
        ];
    }
}
