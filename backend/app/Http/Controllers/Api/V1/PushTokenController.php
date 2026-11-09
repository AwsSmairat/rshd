<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\RegisterPushTokenRequest;
use App\Http\Requests\Api\V1\UnregisterPushTokenRequest;
use App\Models\User;
use App\Services\Push\PushNotificationService;
use Illuminate\Http\JsonResponse;
use Laravel\Sanctum\PersonalAccessToken;

class PushTokenController extends Controller
{
    /**
     * Registers this install's FCM token for the signed-in session.
     */
    public function store(RegisterPushTokenRequest $request, PushNotificationService $push): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();
        $session = $user->currentAccessToken();

        if (! $session instanceof PersonalAccessToken) {
            return $this->forbiddenResponse();
        }

        // The device is the one this session was issued to, never one the
        // request claims.
        $deviceId = str_starts_with((string) $session->name, 'device:')
            ? substr((string) $session->name, strlen('device:'))
            : null;

        $push->register(
            user: $user,
            session: $session,
            token: (string) $request->validated('token'),
            platform: (string) $request->validated('platform'),
            deviceId: $deviceId,
            appVersion: $request->validated('app_version'),
        );

        return $this->successResponse(
            ['push_enabled' => $push->enabled()],
            'تم تفعيل الإشعارات على هذا الجهاز.',
        );
    }

    public function destroy(UnregisterPushTokenRequest $request, PushNotificationService $push): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $push->unregister($user, (string) $request->validated('token'));

        return $this->successResponse(null, 'تم إيقاف الإشعارات على هذا الجهاز.');
    }
}
