<?php

namespace App\Models;

use App\Enums\VideoStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Storage;

class Video extends Model
{
    /**
     * @var list<string>
     */
    protected $fillable = [
        'lesson_id',
        'title',
        'storage_provider',
        'video_url',
        'video_path',
        'original_file_name',
        'file_size',
        'file_mime_type',
        'duration_seconds',
        'status',
        'is_free',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'status' => VideoStatus::class,
            'duration_seconds' => 'integer',
            'file_size' => 'integer',
            'is_free' => 'boolean',
        ];
    }

    protected static function booted(): void
    {
        static::deleting(function (Video $video): void {
            $video->deleteStoredFile();
        });
    }

    public function resolvedVideoUrl(): ?string
    {
        if ($this->video_path) {
            return url(Storage::disk('public')->url($this->video_path));
        }

        if ($this->video_url === null || $this->video_url === '') {
            return null;
        }

        if (str_starts_with($this->video_url, 'http://') ||
            str_starts_with($this->video_url, 'https://')) {
            return $this->video_url;
        }

        return url(Storage::disk('public')->url($this->video_url));
    }

    public function deleteStoredFile(): void
    {
        if (! $this->video_path) {
            return;
        }

        Storage::disk('public')->delete($this->video_path);
    }

    /**
     * @return BelongsTo<Lesson, $this>
     */
    public function lesson(): BelongsTo
    {
        return $this->belongsTo(Lesson::class);
    }

    /**
     * @return HasMany<VideoWatchProgress, $this>
     */
    public function progress(): HasMany
    {
        return $this->hasMany(VideoWatchProgress::class);
    }
}
