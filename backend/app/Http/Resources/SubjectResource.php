<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class SubjectResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'instructor_id' => $this->instructor_id,
            'title' => $this->title,
            'description' => $this->description,
            'category' => $this->category?->value,
            'cover_image' => $this->resolvedCoverImageUrl(),
            'status' => $this->status?->value,
            'price' => $this->price,
            'enrollment_status' => $this->resource->getAttribute('enrollment_status'),
            'progress_percent' => (float) ($this->resource->getAttribute('progress_percent') ?? 0),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'instructor' => UserResource::make($this->whenLoaded('instructor')),
            'lessons' => LessonResource::collection($this->whenLoaded('lessons')),
        ];
    }

    protected function resolvedCoverImageUrl(): ?string
    {
        $path = $this->cover_image;
        if ($path === null || $path === '') {
            return null;
        }

        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return $path;
        }

        return url(Storage::disk('public')->url($path));
    }
}
