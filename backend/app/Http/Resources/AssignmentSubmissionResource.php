<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AssignmentSubmissionResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'assignment_id' => $this->assignment_id,
            'student_id' => $this->student_id,
            'answer_text' => $this->answer_text,
            'file_url' => $this->resolvedFileUrl(),
            'original_file_name' => $this->original_file_name,
            'file_size' => $this->file_size,
            'file_mime_type' => $this->file_mime_type,
            'grade' => $this->grade,
            'feedback' => $this->feedback,
            'submitted_at' => $this->submitted_at,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
