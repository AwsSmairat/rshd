<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\AppleAuthRequest;
use App\Http\Requests\Api\V1\GoogleAuthRequest;
use App\Http\Requests\Api\V1\LoginRequest;
use App\Http\Requests\Api\V1\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\AppleAuthService;
use App\Services\DeviceService;
use App\Services\GoogleAuthService;
use App\Services\LoginThrottleService;
use App\Services\PlatformAuditService;
use App\Services\PlatformSettingsService;
use App\Services\StudentEmailVerificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public const OAUTH_PASSWORD_LOGIN_MESSAGE =
        'This account uses Google or Apple sign-in. Please continue with the original provider.';

    public function register(
        RegisterRequest $request,
        StudentEmailVerificationService $verificationService,
        PlatformSettingsService $settings,
        PlatformAuditService $audit,
    ): JsonResponse {
        $validated = $request->validated();

        $status = $settings->stringValue('default_account_status', 'active', 'registration') === 'pending'
            ? UserStatus::Blocked
            : UserStatus::Active;

        $requiresVerification = $settings->emailVerificationRequired();

        $user = User::query()->create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'phone' => $validated['phone'] ?? null,
            'password' => $validated['password'],
            'role' => UserRole::Student,
            'status' => $status,
            'password_set_at' => now(),
            'email_verified_at' => $requiresVerification ? null : now(),
        ]);

        $user->assignRole('student');

        $audit->logAuth('register.created', $user, 'تم تسجيل الطالب «'.$user->email.'».', $user);

        if ($status === UserStatus::Blocked) {
            return $this->successResponse([
                'email' => $user->email,
                'requires_email_verification' => false,
                'account_pending_review' => true,
            ], 'تم إنشاء الحساب. حسابك قيد المراجعة من الإدارة.', 201);
        }

        if ($requiresVerification) {
            $verificationService->sendCode($user);

            return $this->successResponse([
                'email' => $user->email,
                'requires_email_verification' => true,
            ], 'تم إنشاء الحساب. تم إرسال رمز التحقق إلى بريدك الإلكتروني.', 201);
        }

        if (! app(DeviceService::class)->assertStudentDeviceAllowed($user, $this->devicePayload($validated))) {
            return $this->forbiddenResponse(DeviceService::DEVICE_MISMATCH_MESSAGE);
        }

        $token = $user->createToken('api')->plainTextToken;

        return $this->successResponse([
            'token' => $token,
            'user' => (new UserResource($user->load('activeStudentDevice')))->resolve($request),
            'requires_email_verification' => false,
        ], 'تم إنشاء الحساب بنجاح.', 201);
    }

    public function login(
        LoginRequest $request,
        StudentEmailVerificationService $verificationService,
        PlatformSettingsService $settings,
        LoginThrottleService $throttle,
        PlatformAuditService $audit,
    ): JsonResponse {
        $validated = $request->validated();
        $email = (string) $validated['email'];

        if ($throttle->tooManyAttempts($email)) {
            throw ValidationException::withMessages([
                'email' => ["تم تجاوز عدد محاولات الدخول. يرجى المحاولة بعد {$throttle->lockoutMinutes()} دقيقة."],
            ]);
        }

        $user = User::query()->where('email', $email)->first();

        if ($user && $user->isInstructor() && ! $user->hasSetPassword()) {
            return $this->forbiddenResponse(
                'يجب تعيين كلمة المرور أولاً من رابط الدعوة المرسل إلى بريدك.',
            );
        }

        if ($user && $user->isStudent() && $user->isOAuthOnly()) {
            $throttle->hit($email);
            $audit->logAuth('login.failed', $user, 'محاولة دخول بكلمة مرور لحساب OAuth «'.$email.'».');

            throw ValidationException::withMessages([
                'email' => [self::OAUTH_PASSWORD_LOGIN_MESSAGE],
            ]);
        }

        if (! $user || ! $user->password || ! Hash::check($validated['password'], $user->password)) {
            $throttle->hit($email);
            $audit->logAuth('login.failed', $user, 'محاولة دخول فاشلة للحساب «'.$email.'».');

            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        if ($user->status === UserStatus::Blocked) {
            throw ValidationException::withMessages([
                'email' => ['حسابك غير مفعّل حالياً. يرجى التواصل مع الإدارة.'],
            ]);
        }

        if ($user->isStudent() && $settings->emailVerificationRequired() && $user->email_verified_at === null) {
            $verificationService->sendCode($user);

            return response()->json([
                'success' => false,
                'message' => 'يرجى تأكيد بريدك الإلكتروني قبل تسجيل الدخول.',
                'data' => [
                    'email' => $user->email,
                    'requires_email_verification' => true,
                ],
                'errors' => new \stdClass,
            ], 403);
        }

        if (! app(DeviceService::class)->assertStudentDeviceAllowed($user, $this->devicePayload($validated))) {
            return $this->forbiddenResponse(DeviceService::DEVICE_MISMATCH_MESSAGE);
        }

        $token = $user->createToken('api')->plainTextToken;

        $throttle->clear($email);
        $audit->logAuth('login.success', $user, 'دخول ناجح للحساب «'.$email.'».', $user);

        return $this->successResponse([
            'token' => $token,
            'user' => (new UserResource($user))->resolve($request),
        ], 'تم تسجيل الدخول بنجاح.');
    }

    public function googleAuth(
        GoogleAuthRequest $request,
        GoogleAuthService $googleAuthService,
    ): JsonResponse {
        $validated = $request->validated();

        try {
            $googleProfile = $googleAuthService->verifyIdToken($validated['id_token']);
            $user = $googleAuthService->resolveStudentUser($googleProfile);
        } catch (\RuntimeException $exception) {
            return $this->forbiddenResponse($exception->getMessage());
        }

        if ($user->status === UserStatus::Blocked) {
            return $this->forbiddenResponse('حسابك غير مفعّل حالياً. يرجى التواصل مع الإدارة.');
        }

        if (! app(DeviceService::class)->assertStudentDeviceAllowed($user, $this->devicePayload($validated))) {
            return $this->forbiddenResponse(DeviceService::DEVICE_MISMATCH_MESSAGE);
        }

        $token = $user->createToken('api')->plainTextToken;

        return $this->successResponse([
            'token' => $token,
            'user' => (new UserResource($user))->resolve($request),
        ], 'تم تسجيل الدخول بنجاح.');
    }

    public function appleAuth(
        AppleAuthRequest $request,
        AppleAuthService $appleAuthService,
    ): JsonResponse {
        $validated = $request->validated();

        try {
            $appleProfile = $appleAuthService->verifyIdentityToken($validated['identity_token']);
            $user = $appleAuthService->resolveStudentUser($appleProfile, [
                'name' => $validated['name'] ?? null,
            ]);
        } catch (\RuntimeException $exception) {
            return $this->forbiddenResponse($exception->getMessage());
        }

        if ($user->status === UserStatus::Blocked) {
            return $this->forbiddenResponse('حسابك غير مفعّل حالياً. يرجى التواصل مع الإدارة.');
        }

        if (! app(DeviceService::class)->assertStudentDeviceAllowed($user, $this->devicePayload($validated))) {
            return $this->forbiddenResponse(DeviceService::DEVICE_MISMATCH_MESSAGE);
        }

        $token = $user->createToken('api')->plainTextToken;

        return $this->successResponse([
            'token' => $token,
            'user' => (new UserResource($user))->resolve($request),
        ], 'تم تسجيل الدخول بنجاح.');
    }

    public function logout(Request $request, PlatformAuditService $audit): JsonResponse
    {
        $user = $request->user();
        $audit->logAuth('logout', $user, 'تم تسجيل الخروج.', $user);
        $user->currentAccessToken()->delete();

        return $this->successResponse(null, 'تم تسجيل الخروج بنجاح.');
    }

    public function me(Request $request, PlatformSettingsService $settings): JsonResponse
    {
        $user = $request->user();

        if ($user->isStudent() && $settings->emailVerificationRequired() && $user->email_verified_at === null) {
            return $this->forbiddenResponse(
                'يرجى تأكيد بريدك الإلكتروني قبل استخدام التطبيق.',
            );
        }

        if ($user->status === UserStatus::Blocked) {
            return $this->forbiddenResponse('حسابك غير مفعّل حالياً. يرجى التواصل مع الإدارة.');
        }

        if ($user->isStudent()) {
            $user->load('activeStudentDevice');
        }

        return $this->successResource(new UserResource($user));
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
