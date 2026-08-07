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
        'external_video_id',
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

    public static function storageDiskName(): string
    {
        return (string) config('video.local.disk', 'lesson_videos');
    }

    public static function legacyPublicDiskName(): string
    {
        return (string) config('video.local.legacy_public_disk', 'public');
    }

    /**
     * External/demo playback source only. Never exposes local disk paths.
     */
    public function resolvedExternalVideoUrl(): ?string
    {
        if ($this->video_url === null || $this->video_url === '') {
            return null;
        }

        if (str_starts_with($this->video_url, 'http://') ||
            str_starts_with($this->video_url, 'https://')) {
            return $this->video_url;
        }

        return null;
    }

    public function hasLocalStoredFile(): bool
    {
        if ($this->video_path === null || $this->video_path === '') {
            return false;
        }

        $primary = Storage::disk(static::storageDiskName());

        if ($primary->exists($this->video_path)) {
            return true;
        }

        $legacyDisk = static::legacyPublicDiskName();

        if (static::storageDiskName() !== $legacyDisk) {
            return Storage::disk($legacyDisk)->exists($this->video_path);
        }

        return false;
    }

    public function deleteStoredFile(): void
    {
        if ($this->video_path === null || $this->video_path === '') {
            return;
        }

        Storage::disk(static::storageDiskName())->delete($this->video_path);

        $legacyDisk = static::legacyPublicDiskName();

        if (static::storageDiskName() !== $legacyDisk) {
            Storage::disk($legacyDisk)->delete($this->video_path);
        }
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
