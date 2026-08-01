<?php

namespace App\Models;

use App\Enums\FileType;
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
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'file_type' => FileType::class,
            'file_size' => 'integer',
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
        if ($this->file_path) {
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

    public function deleteStoredFile(): void
    {
        if (! $this->file_path) {
            return;
        }

        Storage::disk('public')->delete($this->file_path);
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
