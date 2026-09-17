<?php

namespace App\Services;

use App\Enums\UserStatus;
use App\Models\StudentDevice;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class StudentSettingsService
{
    public const AVATAR_MAX_KB = 2048;

    /** @var list<string> */
    public const ALLOWED_AVATAR_MIMES = ['image/jpeg', 'image/png', 'image/webp'];

    public function __construct(
        protected DeviceService $deviceService,
        protected PlatformSettingsService $platformSettings,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function defaultPreferences(): array
    {
        return [
            'notify_lessons' => true,
            'notify_assignments' => true,
            'notify_assignment_reminders' => true,
            'notify_quizzes' => true,
            'notify_quiz_reminders' => true,
            'notify_grades' => true,
            'notify_messages' => true,
            'notify_announcements' => true,
            'notify_platform_updates' => true,
            'notification_sound' => true,
            'notification_vibration' => true,
            'language' => 'ar',
            'theme' => 'light',
            'font_size' => 'medium',
            'downloads_wifi_only' => true,
            'auto_play_video' => false,
            'default_video_quality' => 'auto',
            'save_watch_position' => true,
            'timezone' => config('app.timezone', 'Asia/Amman'),
            'profile_visibility' => 'teachers_only',
            'messaging_permission' => 'teachers_only',
            'show_activity_status' => true,
            'allow_profile_photo_use' => true,
            'two_factor_enabled' => false,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function buildSettingsPayload(User $user): array
    {
        $user->loadMissing(['activeStudentDevice', 'studentDevices']);

        $preferences = array_merge(
            $this->defaultPreferences(),
            is_array($user->preferences) ? $user->preferences : [],
        );

        return [
            'profile' => $this->profilePayload($user),
            'preferences' => $preferences,
            'devices' => $user->studentDevices
                ->sortByDesc('last_login_at')
                ->values()
                ->map(fn (StudentDevice $device) => $this->devicePayload($device))
                ->all(),
        ];
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function updateProfile(User $user, array $data): User
    {
        $user->update([
            'name' => $data['name'] ?? $user->name,
            'phone' => $data['phone'] ?? $user->phone,
            'birth_date' => $data['birth_date'] ?? $user->birth_date,
            'gender' => $data['gender'] ?? $user->gender,
            'country' => $data['country'] ?? $user->country,
        ]);

        return $user->fresh();
    }

    public function uploadAvatar(User $user, UploadedFile $file): User
    {
        $this->assertValidAvatar($file);

        $path = $file->store('student-avatars', 'public');
        $previous = $user->resolvedAvatarPath();

        $user->update(['avatar_path' => $path]);

        if ($previous !== null && $previous !== $path) {
            Storage::disk('public')->delete($previous);
        }

        return $user->fresh();
    }

    public function deleteAvatar(User $user): User
    {
        $previous = $user->resolvedAvatarPath();

        $user->update(['avatar_path' => null]);

        if ($previous !== null) {
            Storage::disk('public')->delete($previous);
        }

        return $user->fresh();
    }

    /**
     * @param  array{current_password: string, password: string}  $data
     */
    public function updatePassword(User $user, array $data): void
    {
        if (! Hash::check($data['current_password'], (string) $user->password)) {
            throw ValidationException::withMessages([
                'current_password' => ['كلمة المرور الحالية غير صحيحة.'],
            ]);
        }

        $user->update([
            'password' => $data['password'],
            'password_set_at' => now(),
        ]);
    }

    /**
     * @param  array<string, mixed>  $patch
     */
    public function updatePreferences(User $user, array $patch): User
    {
        $allowed = array_keys($this->defaultPreferences());
        $filtered = array_intersect_key($patch, array_flip($allowed));

        $preferences = array_merge(
            $this->defaultPreferences(),
            is_array($user->preferences) ? $user->preferences : [],
            $filtered,
        );

        $user->update(['preferences' => $preferences]);

        return $user->fresh();
    }

    public function revokeDevice(User $user, StudentDevice $device, ?string $currentDeviceId = null): void
    {
        if ($device->student_id !== $user->id) {
            abort(404);
        }

        if ($currentDeviceId !== null && $device->device_id === $currentDeviceId) {
            throw ValidationException::withMessages([
                'device' => ['لا يمكن إلغاء الجلسة الحالية من هنا. استخدم تسجيل الخروج.'],
            ]);
        }

        $device->update(['is_active' => false]);
    }

    public function logoutOtherDevices(User $user, string $currentTokenId): int
    {
        $deleted = $user->tokens()->where('id', '!=', $currentTokenId)->delete();

        StudentDevice::query()
            ->where('student_id', $user->id)
            ->where('is_active', true)
            ->update(['is_active' => false]);

        return $deleted;
    }

    public function deleteAccount(User $user, string $password): void
    {
        if (! Hash::check($password, (string) $user->password)) {
            throw ValidationException::withMessages([
                'password' => ['كلمة المرور غير صحيحة.'],
            ]);
        }

        $avatarPath = $user->resolvedAvatarPath();

        $submissionPaths = \App\Models\AssignmentSubmission::query()
            ->where('student_id', $user->id)
            ->whereNotNull('file_path')
            ->pluck('file_path')
            ->filter(fn ($path): bool => is_string($path) && $path !== '')
            ->values()
            ->all();

        \Illuminate\Support\Facades\DB::transaction(function () use ($user): void {
            $user->tokens()->delete();
            $user->roles()->detach();
            $user->permissions()->detach();
            $user->delete();
        });

        if ($avatarPath !== null) {
            Storage::disk('public')->delete($avatarPath);
        }

        if ($submissionPaths !== []) {
            Storage::disk('local')->delete($submissionPaths);
        }
    }

    protected function assertValidAvatar(UploadedFile $file): void
    {
        if (! in_array($file->getMimeType(), self::ALLOWED_AVATAR_MIMES, true)) {
            throw ValidationException::withMessages([
                'avatar' => ['نوع الملف غير مدعوم. استخدم JPG أو PNG أو WebP.'],
            ]);
        }

        if ($file->getSize() > self::AVATAR_MAX_KB * 1024) {
            throw ValidationException::withMessages([
                'avatar' => ['حجم الصورة يجب ألا يتجاوز '.self::AVATAR_MAX_KB.'KB.'],
            ]);
        }
    }

    /**
     * @return array<string, mixed>
     */
    protected function profilePayload(User $user): array
    {
        $avatarPath = $user->resolvedAvatarPath();
        // Serve through the authenticated API so the app never depends on the
        // public /storage symlink (staging currently 403s those URLs).
        $avatarUrl = $avatarPath !== null
            ? url('/api/v1/student/avatar').'?v='.($user->updated_at?->timestamp ?? time())
            : null;

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'birth_date' => $user->birth_date?->format('Y-m-d'),
            'gender' => $user->gender,
            'country' => $user->country,
            'student_number' => $user->student_number ?? (string) $user->id,
            'role' => $user->role?->value,
            'status' => $user->status?->value,
            'avatar_url' => $avatarUrl,
            'password_set_at' => $user->password_set_at,
            'created_at' => $user->created_at,
            'updated_at' => $user->updated_at,
            'active_device' => $user->activeStudentDevice
                ? $this->devicePayload($user->activeStudentDevice)
                : null,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    protected function devicePayload(StudentDevice $device): array
    {
        return [
            'id' => $device->id,
            'device_id' => $device->device_id,
            'device_name' => $device->device_name,
            'platform' => $device->platform,
            'is_active' => (bool) $device->is_active,
            'last_login_at' => $device->last_login_at,
            'created_at' => $device->created_at,
        ];
    }
}
