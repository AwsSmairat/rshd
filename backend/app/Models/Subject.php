<?php

namespace App\Models;

use App\Enums\ContentStatus;
use App\Enums\SubjectCategory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Subject extends Model
{
    /**
     * @var list<string>
     */
    protected $fillable = [
        'instructor_id',
        'title',
        'description',
        'category',
        'cover_image',
        'status',
        'price',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'category' => SubjectCategory::class,
            'status' => ContentStatus::class,
            'price' => 'decimal:2',
        ];
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function instructor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'instructor_id');
    }

    /**
     * @return HasMany<Lesson, $this>
     */
    public function lessons(): HasMany
    {
        return $this->hasMany(Lesson::class);
    }

    /**
     * @return BelongsToMany<User, $this>
     */
    public function students(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'subject_students', 'subject_id', 'student_id')
            ->using(SubjectStudent::class)
            ->withPivot(['activated_by', 'payment_status', 'access_status', 'activated_at', 'expires_at'])
            ->withTimestamps();
    }

    /**
     * @return HasMany<SubjectStudent, $this>
     */
    public function enrollments(): HasMany
    {
        return $this->hasMany(SubjectStudent::class);
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

    /**
     * @return HasMany<Announcement, $this>
     */
    public function announcements(): HasMany
    {
        return $this->hasMany(Announcement::class);
    }
}
