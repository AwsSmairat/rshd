<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\URL;

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

    /**
     * A signed link, valid for 30 minutes, through which staff open the
     * student's file (see AssignmentSubmissionFileController).
     */
    public function resolvedFileUrl(): ?string
    {
        if (! $this->hasAttachedFile()) {
            return null;
        }

        return URL::temporarySignedRoute(
            'admin.assignment-submissions.file',
            now()->addMinutes(30),
            ['submission' => $this->getKey()],
        );
    }

    /**
     * The student's file name, cleaned for a download header.
     */
    public function downloadName(): string
    {
        $extension = pathinfo((string) $this->file_path, PATHINFO_EXTENSION);
        $name = preg_replace('/[\x00-\x1F\x7F\/\\\\"%]+/u', '', (string) $this->original_file_name) ?? '';
        $name = trim($name);

        return $name !== '' ? $name : 'submission-'.$this->getKey().($extension !== '' ? '.'.$extension : '');
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
