<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VideoWatchProgress extends Model
{
    protected $table = 'video_watch_progress';

    /**
     * @var list<string>
     */
    protected $fillable = [
        'student_id',
        'video_id',
        'watched_seconds',
        'current_position',
        'completion_percentage',
        'replay_count',
        'last_watched_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'watched_seconds' => 'integer',
            'current_position' => 'integer',
            'completion_percentage' => 'decimal:2',
            'replay_count' => 'integer',
            'last_watched_at' => 'datetime',
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
     * @return BelongsTo<Video, $this>
     */
    public function video(): BelongsTo
    {
        return $this->belongsTo(Video::class);
    }
}
