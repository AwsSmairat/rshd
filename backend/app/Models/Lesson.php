<?php

namespace App\Models;

use App\Enums\ContentStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Lesson extends Model
{
    protected static function booted(): void
    {
        static::creating(function (Lesson $lesson): void {
            $lesson->order = $lesson->normalizedOrderForSubject();
        });

        static::updating(function (Lesson $lesson): void {
            if ($lesson->isDirty(['order', 'subject_id'])) {
                $lesson->order = $lesson->normalizedOrderForSubject($lesson->getKey());
            }
        });
    }

    /**
     * @var list<string>
     */
    protected $fillable = [
        'subject_id',
        'title',
        'description',
        'order',
        'status',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'status' => ContentStatus::class,
            'order' => 'integer',
        ];
    }

    public static function resequenceForSubject(int $subjectId): void
    {
        $lessons = self::query()
            ->where('subject_id', $subjectId)
            ->orderBy('order')
            ->orderBy('id')
            ->get();

        foreach ($lessons as $index => $lesson) {
            $order = $index + 1;

            if ((int) $lesson->order === $order) {
                continue;
            }

            $lesson->updateQuietly(['order' => $order]);
        }
    }

    /**
     * @return BelongsTo<Subject, $this>
     */
    public function subject(): BelongsTo
    {
        return $this->belongsTo(Subject::class);
    }

    /**
     * @return HasMany<Video, $this>
     */
    public function videos(): HasMany
    {
        return $this->hasMany(Video::class);
    }

    /**
     * @return HasMany<LessonFile, $this>
     */
    public function files(): HasMany
    {
        return $this->hasMany(LessonFile::class);
    }

    /**
     * @return HasMany<Assignment, $this>
     */
    public function assignments(): HasMany
    {
        return $this->hasMany(Assignment::class);
    }

    /**
     * @return HasMany<Quiz, $this>
     */
    public function quizzes(): HasMany
    {
        return $this->hasMany(Quiz::class);
    }

    private function normalizedOrderForSubject(?int $ignoreLessonId = null): int
    {
        if (! is_int($this->subject_id) || $this->subject_id <= 0) {
            return max(1, (int) ($this->order ?? 1));
        }

        $siblingsQuery = self::query()->where('subject_id', $this->subject_id);

        if ($ignoreLessonId !== null) {
            $siblingsQuery->whereKeyNot($ignoreLessonId);
        }

        $takenOrders = $siblingsQuery
            ->pluck('order')
            ->map(fn ($order): int => (int) $order)
            ->all();

        $desired = (int) ($this->order ?? 0);

        if ($desired <= 0) {
            return max(1, (count($takenOrders) > 0 ? max($takenOrders) : 0) + 1);
        }

        if (! in_array($desired, $takenOrders, true)) {
            return $desired;
        }

        return max(1, (count($takenOrders) > 0 ? max($takenOrders) : 0) + 1);
    }
}
