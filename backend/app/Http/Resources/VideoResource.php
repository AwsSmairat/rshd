<?php

namespace App\Http\Resources;

use App\Services\VideoAccessService;
use App\Services\VideoPlaybackService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class VideoResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $user = $request->user();
        $canPlay = $user !== null && app(VideoAccessService::class)->canPlay($user, $this->resource);

        $playback = null;

        if ($canPlay && $user !== null) {
            $playback = app(VideoPlaybackService::class)->generatePlaybackUrl($this->resource, $user);
        }

        return [
            'id' => $this->id,
            'lesson_id' => $this->lesson_id,
            'title' => $this->title,
            'is_free' => (bool) $this->is_free,
            'is_locked' => ! $canPlay,
            'duration_seconds' => $this->duration_seconds,
            'status' => $this->status?->value,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'playback' => $playback !== null ? [
                'url' => $playback['url'],
                'expires_at' => $playback['expires_at']->toIso8601String(),
                'type' => $playback['type'] ?? 'hls',
            ] : null,
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
}
