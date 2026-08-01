<?php

namespace App\Models;

use App\Enums\ContentStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Storage;

class Assignment extends Model
{
    /**
     * @var list<string>
     */
    protected $fillable = [
        'subject_id',
        'lesson_id',
        'title',
        'description',
        'attachment_path',
        'original_file_name',
        'file_size',
        'file_mime_type',
        'due_date',
        'status',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'status' => ContentStatus::class,
            'due_date' => 'datetime',
            'file_size' => 'integer',
        ];
    }

    protected static function booted(): void
    {
        static::deleting(function (Assignment $assignment): void {
            $assignment->deleteStoredAttachment();
        });
    }

    public function resolvedAttachmentUrl(): ?string
    {
        if ($this->attachment_path === null || $this->attachment_path === '') {
            return null;
        }

        return url(Storage::disk('public')->url($this->attachment_path));
    }

    public function hasAttachment(): bool
    {
        return $this->attachment_path !== null && $this->attachment_path !== '';
    }

    public function deleteStoredAttachment(): void
    {
        if (! $this->attachment_path) {
            return;
        }

        Storage::disk('public')->delete($this->attachment_path);
    }

    /**
     * @return BelongsTo<Subject, $this>
     */
    public function subject(): BelongsTo
    {
        return $this->belongsTo(Subject::class);
    }

    /**
     * @return BelongsTo<Lesson, $this>
     */
    public function lesson(): BelongsTo
    {
        return $this->belongsTo(Lesson::class);
    }

    /**
     * @return HasMany<AssignmentSubmission, $this>
     */
    public function submissions(): HasMany
    {
        return $this->hasMany(AssignmentSubmission::class);
    }
}
