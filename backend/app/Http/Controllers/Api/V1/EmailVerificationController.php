<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\EmailVerificationException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\ResendEmailVerificationRequest;
use App\Http\Requests\Api\V1\VerifyEmailRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\DeviceService;
use App\Services\StudentEmailVerificationService;
use Illuminate\Http\JsonResponse;

class EmailVerificationController extends Controller
{
    public function verify(
        VerifyEmailRequest $request,
        StudentEmailVerificationService $verificationService,
    ): JsonResponse {
        $validated = $request->validated();

        $user = User::query()
            ->where('email', $validated['email'])
            ->first();

        if ($user === null || ! $user->isStudent()) {
            return $this->errorResponse('المستخدم غير موجود.', 404);
        }

        if ($user->email_verified_at !== null) {
            if (! app(DeviceService::class)->assertStudentDeviceAllowed($user, $this->devicePayload($validated))) {
                return $this->forbiddenResponse(
                DeviceService::DEVICE_MISMATCH_MESSAGE,
                DeviceService::DEVICE_MISMATCH_CODE,
            );
            }

            $token = $user->createToken('api')->plainTextToken;

            return $this->successResponse([
                'token' => $token,
                'user' => (new UserResource($user->load('activeStudentDevice')))->resolve($request),
            ], 'تم تأكيد البريد الإلكتروني بنجاح.');
        }

        try {
            $verificationService->verifyCode($user, $validated['code']);
        } catch (EmailVerificationException $exception) {
            return $this->errorResponse($exception->getMessage(), $exception->httpStatus);
        }

        $user->refresh();

        if (! app(DeviceService::class)->assertStudentDeviceAllowed($user, $this->devicePayload($validated))) {
            return $this->forbiddenResponse(
                DeviceService::DEVICE_MISMATCH_MESSAGE,
                DeviceService::DEVICE_MISMATCH_CODE,
            );
        }

        $token = $user->createToken('api')->plainTextToken;

        return $this->successResponse([
            'token' => $token,
            'user' => (new UserResource($user->load('activeStudentDevice')))->resolve($request),
        ], 'تم تأكيد البريد الإلكتروني بنجاح.');
    }

    public function resend(
        ResendEmailVerificationRequest $request,
        StudentEmailVerificationService $verificationService,
    ): JsonResponse {
        $validated = $request->validated();

        $user = User::query()
            ->where('email', $validated['email'])
            ->first();

        if ($user === null || ! $user->isStudent()) {
            return $this->errorResponse('المستخدم غير موجود.', 404);
        }

        if ($user->email_verified_at !== null) {
            return $this->successResponse(null, 'البريد الإلكتروني مؤكد بالفعل.');
        }

        try {
            $verificationService->resendCode($user);
        } catch (EmailVerificationException $exception) {
            return $this->errorResponse($exception->getMessage(), $exception->httpStatus);
        }

        return $this->successResponse(null, 'تم إرسال رمز تحقق جديد إلى بريدك الإلكتروني');
    }

    /**
     * @param  array<string, mixed>  $validated
     * @return array{device_id?: string|null, device_name?: string|null, platform?: string|null}
     */
    private function devicePayload(array $validated): array
    {
        return [
            'device_id' => $validated['device_id'] ?? null,
            'device_name' => $validated['device_name'] ?? null,
            'platform' => $validated['platform'] ?? null,
        ];
    }
}
