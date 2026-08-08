<?php

namespace App\Models;

use App\Enums\FileType;
use App\Enums\LessonFileStorageStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Storage;

class LessonFile extends Model
{
    /**
     * @var list<string>
     */
    protected $fillable = [
        'lesson_id',
        'title',
        'file_type',
        'file_path',
        'original_file_name',
        'file_url',
        'file_size',
        'file_mime_type',
        'storage_provider',
        'storage_disk',
        'external_path',
        'storage_status',
        'uploaded_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'file_type' => FileType::class,
            'file_size' => 'integer',
            'storage_status' => LessonFileStorageStatus::class,
            'uploaded_at' => 'datetime',
        ];
    }

    protected static function booted(): void
    {
        static::deleting(function (LessonFile $file): void {
            $file->deleteStoredFile();
        });
    }

    public function resolvedFileUrl(): ?string
    {
        if ($this->requiresSignedDownload()) {
            return null;
        }

        if ($this->file_path) {
            if ($this->localSourceDiskName() !== 'public') {
                return null;
            }

            return url(Storage::disk('public')->url($this->file_path));
        }

        if ($this->file_url === null || $this->file_url === '') {
            return null;
        }

        if (str_starts_with($this->file_url, 'http://') ||
            str_starts_with($this->file_url, 'https://')) {
            return $this->file_url;
        }

        return url(Storage::disk('public')->url($this->file_url));
    }

    public function isBunnyStored(): bool
    {
        return $this->storage_provider === 'bunny' && filled($this->external_path);
    }

    public function requiresSignedDownload(): bool
    {
        if ($this->isBunnyStored()) {
            return true;
        }

        return (bool) config('files.signed_download', true);
    }

    public function cdnPath(): ?string
    {
        return $this->external_path;
    }

    public static function defaultLocalSourceDisk(): string
    {
        return (string) config('files.local_disk', 'lesson_files');
    }

    public function localSourceDiskName(): string
    {
        if (filled($this->storage_disk)) {
            return (string) $this->storage_disk;
        }

        return self::defaultLocalSourceDisk();
    }

    public function deleteStoredFile(): void
    {
        if (! $this->file_path) {
            return;
        }

        Storage::disk($this->localSourceDiskName())->delete($this->file_path);
    }

    /**
     * @return BelongsTo<Lesson, $this>
     */
    public function lesson(): BelongsTo
    {
        return $this->belongsTo(Lesson::class);
    }

    /**
     * @return HasMany<PdfAnnotation, $this>
     */
    public function annotations(): HasMany
    {
        return $this->hasMany(PdfAnnotation::class, 'file_id');
    }
}
