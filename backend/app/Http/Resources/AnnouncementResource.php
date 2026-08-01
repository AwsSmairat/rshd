<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class AnnouncementResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'body' => $this->body,
            'type' => $this->type?->value ?? $this->type,
            'image_url' => $this->image
                ? url(Storage::disk('public')->url($this->image))
                : null,
            'subject_id' => $this->subject_id,
            'subject_title' => $this->subject?->title,
            'created_at' => $this->created_at,
        ];
    }
}
