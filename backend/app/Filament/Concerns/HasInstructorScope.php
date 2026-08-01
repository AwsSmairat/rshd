<?php

namespace App\Filament\Concerns;

use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Auth;

trait HasInstructorScope
{
    protected static function authUser(): ?User
    {
        /** @var User|null */
        return Auth::user();
    }

    protected static function isAdmin(): bool
    {
        return static::authUser()?->isAdmin() ?? false;
    }

    protected static function isInstructor(): bool
    {
        return static::authUser()?->isInstructor() ?? false;
    }

    protected static function instructorSubjectIds(): array
    {
        $user = static::authUser();

        if ($user === null) {
            return [];
        }

        return $user->subjectsTeaching()->pluck('id')->all();
    }

    /**
     * @param  Builder<\App\Models\Subject>  $query
     * @return Builder<\App\Models\Subject>
     */
    protected static function scopeSubjectsQuery(Builder $query): Builder
    {
        if (static::isAdmin()) {
            return $query;
        }

        return $query->where('instructor_id', static::authUser()?->id);
    }

    /**
     * @param  Builder<\App\Models\Lesson>  $query
     * @return Builder<\App\Models\Lesson>
     */
    protected static function scopeLessonsQuery(Builder $query): Builder
    {
        if (static::isAdmin()) {
            return $query;
        }

        return $query->whereHas('subject', fn (Builder $q) => $q->where('instructor_id', static::authUser()?->id));
    }

    /**
     * @param  Builder<\Illuminate\Database\Eloquent\Model>  $query
     * @return Builder<\Illuminate\Database\Eloquent\Model>
     */
    protected static function scopeBySubjectInstructor(Builder $query, string $relation = 'subject'): Builder
    {
        if (static::isAdmin()) {
            return $query;
        }

        $instructorId = static::authUser()?->id;

        if (str_contains($relation, '.')) {
            return $query->whereHas($relation, fn (Builder $q) => $q->where('instructor_id', $instructorId));
        }

        return $query->whereHas($relation, fn (Builder $q) => $q->where('instructor_id', $instructorId));
    }

    /**
     * @return array<int|string, string>
     */
    protected static function subjectFilterOptions(): array
    {
        $query = \App\Models\Subject::query();

        return static::scopeSubjectsQuery($query)
            ->orderBy('title')
            ->pluck('title', 'id')
            ->all();
    }

    /**
     * @param  Builder<\Illuminate\Database\Eloquent\Model>  $query
     * @return Builder<\Illuminate\Database\Eloquent\Model>
     */
    protected static function applyLessonSubjectFilter(Builder $query, array $data): Builder
    {
        $subjectId = $data['value'] ?? null;

        if (! filled($subjectId)) {
            return $query;
        }

        return $query->whereHas('lesson', fn (Builder $lessonQuery) => $lessonQuery->where('subject_id', $subjectId));
    }
}
