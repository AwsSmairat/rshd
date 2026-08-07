<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\PasswordResetException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\ForgotPasswordRequest;
use App\Http\Requests\Api\V1\ResendPasswordResetRequest;
use App\Http\Requests\Api\V1\ResetPasswordRequest;
use App\Http\Requests\Api\V1\VerifyPasswordResetRequest;
use App\Services\PlatformAuditService;
use App\Services\StudentPasswordResetService;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\ValidationException;

class PasswordResetController extends Controller
{
    public function forgot(
        ForgotPasswordRequest $request,
        StudentPasswordResetService $resetService,
    ): JsonResponse {
        try {
            $resetService->requestReset($request->validated('email'), $request->ip());
        } catch (PasswordResetException $exception) {
            return $this->errorResponse($exception->getMessage(), $exception->httpStatus);
        }

        return $this->successResponse(
            null,
            StudentPasswordResetService::GENERIC_REQUEST_MESSAGE,
        );
    }

    public function verify(
        VerifyPasswordResetRequest $request,
        StudentPasswordResetService $resetService,
    ): JsonResponse {
        try {
            $result = $resetService->verifyCode(
                $request->validated('email'),
                $request->validated('code'),
                $request->ip(),
            );
        } catch (PasswordResetException $exception) {
            return $this->errorResponse($exception->getMessage(), $exception->httpStatus);
        }

        return $this->successResponse($result, 'تم التحقق من الرمز بنجاح.');
    }

    public function reset(
        ResetPasswordRequest $request,
        StudentPasswordResetService $resetService,
        PlatformAuditService $audit,
    ): JsonResponse {
        $validated = $request->validated();

        try {
            $resetService->resetPassword(
                $validated['email'],
                $validated['reset_token'],
                $validated['password'],
                $request->ip(),
            );
        } catch (PasswordResetException $exception) {
            return $this->errorResponse($exception->getMessage(), $exception->httpStatus);
        } catch (ValidationException $exception) {
            throw $exception;
        }

        $audit->logAuth(
            'password.reset',
            null,
            'تمت استعادة كلمة مرور الطالب «'.$validated['email'].'».',
        );

        return $this->successResponse(null, 'تم تغيير كلمة المرور بنجاح.');
    }

    public function resend(
        ResendPasswordResetRequest $request,
        StudentPasswordResetService $resetService,
    ): JsonResponse {
        try {
            $resetService->resendCode($request->validated('email'), $request->ip());
        } catch (PasswordResetException $exception) {
            return $this->errorResponse($exception->getMessage(), $exception->httpStatus);
        }

        return $this->successResponse(null, 'تم إرسال رمز استعادة جديد إلى بريدك الإلكتروني.');
    }
}
