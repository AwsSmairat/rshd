<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class AssignmentSubmission extends Model
{
    /**
     * @var list<string>
     */
    protected $fillable = [
        'assignment_id',
        'student_id',
        'answer_text',
        'file_url',
        'file_path',
        'original_file_name',
        'file_size',
        'file_mime_type',
        'grade',
        'feedback',
        'submitted_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'grade' => 'decimal:2',
            'submitted_at' => 'datetime',
        ];
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

    /**
     * @return BelongsTo<Assignment, $this>
     */
    public function assignment(): BelongsTo
    {
        return $this->belongsTo(Assignment::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function student(): BelongsTo
    {
        return $this->belongsTo(User::class, 'student_id');
    }
}
