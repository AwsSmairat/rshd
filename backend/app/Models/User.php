<?php

namespace App\Models;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Services\PlatformSettingsService;
use Database\Factories\UserFactory;
use Filament\Models\Contracts\FilamentUser;
use Filament\Models\Contracts\HasAvatar;
use Filament\Panel;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable implements FilamentUser, HasAvatar
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, HasRoles, Notifiable;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'google_id',
        'apple_id',
        'phone',
        'birth_date',
        'gender',
        'country',
        'student_number',
        'avatar_path',
        'preferences',
        'terms_accepted_version',
        'terms_accepted_at',
        'terms_accepted_platform',
        'password',
        'role',
        'status',
        'email_verified_at',
        'invitation_sent_at',
        'password_set_at',
    ];

    /**
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'role' => UserRole::class,
            'status' => UserStatus::class,
            'email_verified_at' => 'datetime',
            'invitation_sent_at' => 'datetime',
            'password_set_at' => 'datetime',
            'terms_accepted_at' => 'datetime',
            'birth_date' => 'date',
            'password' => 'hashed',
            'preferences' => 'array',
        ];
    }

    public function getFilamentAvatarUrl(): ?string
    {
        $path = $this->resolvedAvatarPath();

        if ($path === null) {
            return null;
        }

        $url = Storage::disk('public')->url($path);
        $version = $this->updated_at?->timestamp ?? time();

        return $url.'?v='.$version;
    }

    public function resolvedAvatarPath(): ?string
    {
        $path = $this->avatar_path;

        if (is_array($path)) {
            $path = $path[0] ?? null;
        }

        if (! is_string($path) || $path === '') {
            return null;
        }

        return $path;
    }

    public function initials(int $fallbackLength = 2): string
    {
        $name = trim($this->name);

        if ($name === '') {
            return $this->isInstructor() ? 'م' : 'أ';
        }

        $parts = preg_split('/\s+/u', $name) ?: [];

        if ($fallbackLength === 1) {
            return mb_strtoupper(mb_substr($parts[0] ?? '', 0, 1));
        }

        return mb_strtoupper(
            mb_substr($parts[0] ?? '', 0, 1).mb_substr($parts[1] ?? '', 0, 1)
        );
    }

    public function canAccessPanel(Panel $panel): bool
    {
        if ($this->isAdmin()) {
            return true;
        }

        return $this->isInstructor() && $this->hasSetPassword();
    }

    public function isAdmin(): bool
    {
        return $this->role === UserRole::Admin;
    }

    public function isInstructor(): bool
    {
        return $this->role === UserRole::Instructor;
    }

    public function isStudent(): bool
    {
        return $this->role === UserRole::Student;
    }

    public function hasSetPassword(): bool
    {
        return $this->password_set_at !== null;
    }

    public function isOAuthOnly(): bool
    {
        return $this->password === null
            && ($this->google_id !== null || $this->apple_id !== null);
    }

    public function preference(string $key, mixed $default = null): mixed
    {
        return ($this->preferences ?? [])[$key] ?? $default;
    }

    public function prefersNotification(string $key): bool
    {
        return (bool) $this->preference($key, true);
    }

    public function profileVisibleToStudents(): bool
    {
        return (bool) $this->preference('profile_visible', true);
    }

    public function emailVisibleToStudents(): bool
    {
        return (bool) $this->preference('show_email', false);
    }

    /**
     * @return HasMany<Subject, $this>
     */
    public function subjectsTeaching(): HasMany
    {
        return $this->hasMany(Subject::class, 'instructor_id');
    }

    /**
     * @return BelongsToMany<Subject, $this>
     */
    public function enrolledSubjects(): BelongsToMany
    {
        return $this->belongsToMany(Subject::class, 'subject_students', 'student_id', 'subject_id')
            ->using(SubjectStudent::class)
            ->withPivot(['activated_by', 'payment_status', 'access_status', 'activated_at', 'expires_at'])
            ->withTimestamps();
    }

    /**
     * @return HasMany<StudentDevice, $this>
     */
    public function studentDevices(): HasMany
    {
        return $this->hasMany(StudentDevice::class, 'student_id');
    }

    /**
     * @return HasOne<StudentDevice, $this>
     */
    public function activeStudentDevice(): HasOne
    {
        return $this->hasOne(StudentDevice::class, 'student_id')
            ->where('is_active', true)
            ->latest('last_login_at');
    }

    /**
     * @return HasMany<VideoWatchProgress, $this>
     */
    public function videoProgress(): HasMany
    {
        return $this->hasMany(VideoWatchProgress::class, 'student_id');
    }

    /**
     * @return HasMany<PdfAnnotation, $this>
     */
    public function annotations(): HasMany
    {
        return $this->hasMany(PdfAnnotation::class, 'student_id');
    }

    /**
     * @return HasMany<Grade, $this>
     */
    public function grades(): HasMany
    {
        return $this->hasMany(Grade::class, 'student_id');
    }

    /**
     * @return HasMany<AppNotification, $this>
     */
    public function notifications(): HasMany
    {
        return $this->hasMany(AppNotification::class);
    }

    protected static function booted(): void
    {
        static::updated(function (User $user): void {
            if (! $user->wasChanged('password')) {
                return;
            }

            if (! app(PlatformSettingsService::class)->enabled('force_logout_after_password_change', 'security')) {
                return;
            }

            $user->tokens()->delete();
        });
    }

    public function sendPasswordResetNotification(#[\SensitiveParameter] $token): void
    {
        if (! app(PlatformSettingsService::class)->passwordResetEmailsEnabled()) {
            return;
        }

        $this->notify(new ResetPassword($token));
    }
}
