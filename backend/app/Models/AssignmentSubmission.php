<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

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
        return null;
    }

    public function hasAttachedFile(): bool
    {
        return filled($this->file_path);
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
