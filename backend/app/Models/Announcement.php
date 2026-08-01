<?php

namespace App\Models;

use App\Enums\AnnouncementTargetType;
use App\Enums\AnnouncementType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Announcement extends Model
{
    /**
     * @var list<string>
     */
    protected $fillable = [
        'subject_id',
        'instructor_id',
        'title',
        'body',
        'image',
        'target_type',
        'type',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'target_type' => AnnouncementTargetType::class,
            'type' => AnnouncementType::class,
        ];
    }

    /**
     * @return BelongsTo<Subject, $this>
     */
    public function subject(): BelongsTo
    {
        return $this->belongsTo(Subject::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function instructor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'instructor_id');
    }
}
