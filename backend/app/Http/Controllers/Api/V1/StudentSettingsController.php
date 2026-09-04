<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\DeleteStudentAccountRequest;
use App\Http\Requests\Api\V1\UpdateStudentPasswordRequest;
use App\Http\Requests\Api\V1\UpdateStudentPreferencesRequest;
use App\Http\Requests\Api\V1\UpdateStudentProfileRequest;
use App\Models\StudentDevice;
use App\Models\User;
use App\Services\StudentSettingsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class StudentSettingsController extends Controller
{
    public function show(Request $request, StudentSettingsService $settings): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        if (! $user->isStudent()) {
            return $this->forbiddenResponse('هذه الصفحة متاحة للطلاب فقط.');
        }

        return $this->successResponse($settings->buildSettingsPayload($user));
    }

    public function updateProfile(
        UpdateStudentProfileRequest $request,
        StudentSettingsService $settings,
    ): JsonResponse {
        /** @var User $user */
        $user = $request->user();

        $updated = $settings->updateProfile($user, $request->validated());

        return $this->successResponse(
            $settings->buildSettingsPayload($updated),
            'تم تحديث المعلومات الشخصية بنجاح.',
        );
    }

    public function showAvatar(Request $request): StreamedResponse|JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        if (! $user->isStudent()) {
            return $this->forbiddenResponse('هذه الصفحة متاحة للطلاب فقط.');
        }

        $path = $user->resolvedAvatarPath();

        if ($path === null || ! Storage::disk('public')->exists($path)) {
            abort(404);
        }

        return Storage::disk('public')->response($path, headers: [
            'Cache-Control' => 'private, no-store, no-cache, must-revalidate',
        ]);
    }

    public function uploadAvatar(Request $request, StudentSettingsService $settings): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $request->validate([
            'avatar' => ['required', 'file', 'image', 'max:2048'],
        ]);

        $updated = $settings->uploadAvatar($user, $request->file('avatar'));

        return $this->successResponse(
            $settings->buildSettingsPayload($updated),
            'تم تحديث الصورة الشخصية بنجاح.',
        );
    }

    public function deleteAvatar(Request $request, StudentSettingsService $settings): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $updated = $settings->deleteAvatar($user);

        return $this->successResponse(
            $settings->buildSettingsPayload($updated),
            'تم حذف الصورة الشخصية.',
        );
    }

    public function updatePassword(
        UpdateStudentPasswordRequest $request,
        StudentSettingsService $settings,
    ): JsonResponse {
        /** @var User $user */
        $user = $request->user();

        $settings->updatePassword($user, $request->validated());

        return $this->successResponse(null, 'تم تغيير كلمة المرور بنجاح.');
    }

    public function updatePreferences(
        UpdateStudentPreferencesRequest $request,
        StudentSettingsService $settings,
    ): JsonResponse {
        /** @var User $user */
        $user = $request->user();

        $updated = $settings->updatePreferences($user, $request->validated());

        return $this->successResponse(
            $settings->buildSettingsPayload($updated),
            'تم حفظ الإعدادات بنجاح.',
        );
    }

    public function revokeDevice(
        Request $request,
        StudentDevice $device,
        StudentSettingsService $settings,
    ): JsonResponse {
        /** @var User $user */
        $user = $request->user();

        $settings->revokeDevice(
            $user,
            $device,
            $request->string('current_device_id')->toString() ?: null,
        );

        return $this->successResponse(
            $settings->buildSettingsPayload($user->fresh(['activeStudentDevice', 'studentDevices'])),
            'تم تسجيل الخروج من الجهاز.',
        );
    }

    public function logoutAllDevices(Request $request, StudentSettingsService $settings): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $token = $user->currentAccessToken();
        $deleted = $settings->logoutOtherDevices($user, (string) $token->id);

        return $this->successResponse(
            ['revoked_sessions' => $deleted],
            'تم تسجيل الخروج من جميع الأجهزة الأخرى.',
        );
    }

    public function deleteAccount(
        DeleteStudentAccountRequest $request,
        StudentSettingsService $settings,
    ): JsonResponse {
        /** @var User $user */
        $user = $request->user();

        $settings->deleteAccount($user, $request->validated('password'));

        return $this->successResponse(null, 'تم حذف الحساب.');
    }
}
