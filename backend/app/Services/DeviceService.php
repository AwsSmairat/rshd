<?php

namespace App\Services;

use App\Models\StudentDevice;
use App\Models\User;
use InvalidArgumentException;

class DeviceService
{
    public const DEVICE_MISMATCH_MESSAGE = 'هذا الحساب مرتبط بجهاز آخر. يرجى التواصل مع الإدارة لإعادة تعيين الجهاز.';

    public function __construct(
        protected PlatformSettingsService $settings,
    ) {}

    /**
     * Enforce device binding for students based on platform settings.
     *
     * @param  array{device_id?: string|null, device_name?: string|null, platform?: string|null}  $deviceData
     */
    public function assertStudentDeviceAllowed(User $user, array $deviceData): bool
    {
        if (! $user->isStudent() || ! $this->settings->deviceBindingEnabled()) {
            return true;
        }

        $deviceId = $deviceData['device_id'] ?? null;
        if (empty($deviceId)) {
            return ! $this->settings->deviceIdRequired();
        }

        $activeDevices = StudentDevice::query()
            ->where('student_id', $user->id)
            ->where('is_active', true)
            ->get();

        $matching = $activeDevices->firstWhere('device_id', $deviceId);
        if ($matching !== null) {
            $matching->update([
                'device_name' => $deviceData['device_name'] ?? $matching->device_name,
                'platform' => $deviceData['platform'] ?? $matching->platform,
                'last_login_at' => now(),
            ]);

            return true;
        }

        $maxDevices = max(1, $this->settings->integer('max_active_devices', 1, 'students'));

        if ($activeDevices->count() < $maxDevices) {
            $this->registerOrCheckDevice($user, [
                'device_id' => $deviceId,
                'device_name' => $deviceData['device_name'] ?? null,
                'platform' => $deviceData['platform'] ?? null,
            ]);

            return true;
        }

        return false;
    }

    /**
     * @param  array{device_id: string, device_name?: string|null, platform?: string|null}  $deviceData
     */
    public function registerOrCheckDevice(User $student, array $deviceData): StudentDevice
    {
        if (empty($deviceData['device_id'])) {
            throw new InvalidArgumentException('device_id is required.');
        }

        $maxDevices = max(1, $this->settings->integer('max_active_devices', 1, 'students'));

        $activeDevices = StudentDevice::query()
            ->where('student_id', $student->id)
            ->where('is_active', true)
            ->orderByDesc('last_login_at')
            ->get();

        $existing = $activeDevices->firstWhere('device_id', $deviceData['device_id']);
        if ($existing !== null) {
            $existing->update([
                'device_name' => $deviceData['device_name'] ?? $existing->device_name,
                'platform' => $deviceData['platform'] ?? $existing->platform,
                'last_login_at' => now(),
            ]);

            return $existing;
        }

        if ($activeDevices->count() >= $maxDevices) {
            StudentDevice::query()
                ->where('student_id', $student->id)
                ->where('is_active', true)
                ->orderBy('last_login_at')
                ->limit($activeDevices->count() - $maxDevices + 1)
                ->update(['is_active' => false]);
        }

        return StudentDevice::query()->updateOrCreate(
            [
                'student_id' => $student->id,
                'device_id' => $deviceData['device_id'],
            ],
            [
                'device_name' => $deviceData['device_name'] ?? null,
                'platform' => $deviceData['platform'] ?? null,
                'is_active' => true,
                'last_login_at' => now(),
            ],
        );
    }

    public function resetStudentDevices(User $student, ?User $actor = null): void
    {
        StudentDevice::query()
            ->where('student_id', $student->id)
            ->update(['is_active' => false]);

        app(PlatformAuditService::class)->logDevice(
            'device.reset',
            $actor,
            'تم إعادة تعيين أجهزة الطالب «'.$student->name.'».',
            $student,
        );
    }
}
