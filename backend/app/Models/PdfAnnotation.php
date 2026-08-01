<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PdfAnnotation extends Model
{
    /**
     * @var list<string>
     */
    protected $fillable = [
        'student_id',
        'file_id',
        'annotation_json',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'annotation_json' => 'array',
        ];
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function student(): BelongsTo
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    /**
     * @return BelongsTo<LessonFile, $this>
     */
    public function file(): BelongsTo
    {
        return $this->belongsTo(LessonFile::class, 'file_id');
    }
}
