<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Str;
use Laravel\Sanctum\NewAccessToken;

/**
 * Student sessions in the mobile app.
 *
 * A session is a Sanctum token with no time limit: the student stays signed
 * in until one of these ends it.
 *
 *  - The student signs out (this device), or signs out of every device.
 *  - An admin signs the student out of every device, or resets their devices.
 *  - The student or an admin revokes one of the student's devices.
 *  - The password changes (when "sign out after password change" is on), the
 *    account is blocked, or the account is deleted.
 *
 * Each token is named after the device it was issued to, so ending a
 * device's access also ends that device's session.
 */
class StudentSessionService
{
    private const DEVICE_PREFIX = 'device:';

    private const UNBOUND_NAME = 'api';

    public function issue(User $user, ?string $deviceId): NewAccessToken
    {
        return $user->createToken($this->tokenName($deviceId));
    }

    public function tokenName(?string $deviceId): string
    {
        $deviceId = trim((string) $deviceId);

        // Token names are limited to 255 characters.
        return $deviceId === ''
            ? self::UNBOUND_NAME
            : self::DEVICE_PREFIX.Str::limit($deviceId, 200, '');
    }

    /**
     * Ends every session the user has, on every device.
     */
    public function endAll(User $user): int
    {
        return $user->tokens()->delete();
    }

    /**
     * Ends the sessions issued to one device.
     */
    public function endForDevice(User $user, string $deviceId): int
    {
        return $user->tokens()
            ->where('name', $this->tokenName($deviceId))
            ->delete();
    }
}
