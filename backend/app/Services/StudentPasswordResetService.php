<?php

namespace App\Services;

use App\Enums\UserStatus;
use App\Exceptions\PasswordResetException;
use App\Mail\StudentPasswordResetCodeMail;
use App\Models\StudentPasswordResetCode;
use App\Models\User;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class StudentPasswordResetService
{
    public const GENERIC_REQUEST_MESSAGE =
        'إذا كان البريد الإلكتروني مسجلاً لدينا، فستصلك رسالة تحتوي على رمز الاستعادة.';

    private const FORGOT_EMAIL_MAX = 5;

    private const FORGOT_IP_MAX = 20;

    private const VERIFY_IP_MAX = 30;

    private const RESEND_IP_MAX = 15;

    private const RESET_EMAIL_MAX = 5;

    private const RESET_IP_MAX = 15;

    public const OTP_EXPIRY_SECONDS = 30;

    public const RESEND_COOLDOWN_SECONDS = 30;

    public function __construct(
        protected PlatformSettingsService $settings,
    ) {}

    public function requestReset(string $email, ?string $ip = null): void
    {
        $normalized = $this->normalizeEmail($email);
        $this->assertRateLimit('forgot', $normalized, $ip, self::FORGOT_EMAIL_MAX, self::FORGOT_IP_MAX);

        $user = User::query()->where('email', $normalized)->first();

        if ($this->canResetPassword($user)) {
            $this->sendCode($user);
        }

        $this->hitRateLimit('forgot', $normalized, $ip);
    }

    /**
     * @return array{reset_token: string}
     */
    public function verifyCode(string $email, string $code, ?string $ip = null): array
    {
        $normalized = $this->normalizeEmail($email);
        $this->assertRateLimit('verify', $normalized, $ip, self::VERIFY_IP_MAX, self::VERIFY_IP_MAX);

        $user = $this->findResettableStudent($email);

        $record = StudentPasswordResetCode::query()
            ->where('user_id', $user->id)
            ->whereNull('used_at')
            ->where('expires_at', '>', now())
            ->latest('id')
            ->first();

        if ($record === null) {
            $this->hitRateLimit('verify', $normalized, $ip);
            throw new PasswordResetException('انتهت صلاحية الرمز أو غير موجود');
        }

        $maxAttempts = max(1, $this->settings->integer('max_otp_attempts', 5, 'registration'));
        if ($record->attempts >= $maxAttempts) {
            throw new PasswordResetException('تم تجاوز عدد المحاولات');
        }

        if (! Hash::check($code, $record->code_hash)) {
            $record->increment('attempts');
            $this->hitRateLimit('verify', $normalized, $ip);

            throw new PasswordResetException('الرمز غير صحيح');
        }

        $resetToken = Str::random(64);

        $record->update([
            'reset_token_hash' => Hash::make($resetToken),
            'reset_token_expires_at' => now()->addMinutes(15),
        ]);

        return ['reset_token' => $resetToken];
    }

    public function resetPassword(
        string $email,
        string $resetToken,
        string $password,
        ?string $ip = null,
    ): void {
        $normalized = $this->normalizeEmail($email);
        $this->assertRateLimit('reset', $normalized, $ip, self::RESET_EMAIL_MAX, self::RESET_IP_MAX);

        $user = $this->findResettableStudent($email);

        $record = StudentPasswordResetCode::query()
            ->where('user_id', $user->id)
            ->whereNull('used_at')
            ->whereNotNull('reset_token_hash')
            ->where('reset_token_expires_at', '>', now())
            ->latest('id')
            ->first();

        if ($record === null || ! Hash::check($resetToken, (string) $record->reset_token_hash)) {
            $this->hitRateLimit('reset', $normalized, $ip);
            throw new PasswordResetException('رمز الاستعادة غير صالح أو منتهي');
        }

        $user->update([
            'password' => $password,
            'password_set_at' => now(),
        ]);

        $record->update(['used_at' => now()]);

        StudentPasswordResetCode::query()
            ->where('user_id', $user->id)
            ->whereNull('used_at')
            ->update(['used_at' => now()]);

        $user->tokens()->delete();
    }

    public function resendCode(string $email, ?string $ip = null): void
    {
        $normalized = $this->normalizeEmail($email);
        $this->assertRateLimit('resend', $normalized, $ip, self::RESEND_IP_MAX, self::RESEND_IP_MAX);

        $user = $this->findResettableStudent($email);

        $cooldown = self::RESEND_COOLDOWN_SECONDS;

        $latest = StudentPasswordResetCode::query()
            ->where('user_id', $user->id)
            ->latest('id')
            ->first();

        if ($latest !== null && $latest->created_at->gt(now()->subSeconds($cooldown))) {
            throw new PasswordResetException(
                "يرجى الانتظار {$cooldown} ثانية قبل إعادة إرسال الرمز",
                429,
            );
        }

        $this->sendCode($user);
        $this->hitRateLimit('resend', $normalized, $ip);
    }

    protected function sendCode(User $user): void
    {
        StudentPasswordResetCode::query()
            ->where('user_id', $user->id)
            ->whereNull('used_at')
            ->update(['used_at' => now()]);

        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $expirySeconds = self::OTP_EXPIRY_SECONDS;

        StudentPasswordResetCode::query()->create([
            'user_id' => $user->id,
            'email' => $user->email,
            'code_hash' => Hash::make($code),
            'expires_at' => now()->addSeconds($expirySeconds),
            'attempts' => 0,
        ]);

        if (! $this->settings->passwordResetEmailsEnabled()) {
            return;
        }

        $this->settings->applyMailPreferences();
        Mail::to($user->email)->send(
            new StudentPasswordResetCodeMail($user, $code, $expirySeconds)
        );
    }

    protected function findResettableStudent(string $email): User
    {
        $user = User::query()
            ->where('email', $this->normalizeEmail($email))
            ->first();

        if (! $this->canResetPassword($user)) {
            throw new PasswordResetException('تعذر إكمال عملية الاستعادة.', 404);
        }

        return $user;
    }

    protected function canResetPassword(?User $user): bool
    {
        if ($user === null || ! $user->isStudent()) {
            return false;
        }

        if ($user->status === UserStatus::Blocked) {
            return false;
        }

        if ($user->isOAuthOnly()) {
            return false;
        }

        return $user->password !== null;
    }

    protected function normalizeEmail(string $email): string
    {
        return Str::lower(trim($email));
    }

    /**
     * @return list<string>
     */
    protected function rateLimitKeys(string $action, string $normalizedEmail, ?string $ip): array
    {
        $keys = ['password_reset_'.$action.':email:'.$normalizedEmail];

        if ($ip !== null && $ip !== '') {
            $keys[] = 'password_reset_'.$action.':ip:'.$ip;
        }

        return $keys;
    }

    protected function assertRateLimit(
        string $action,
        string $normalizedEmail,
        ?string $ip,
        int $emailMax,
        int $ipMax,
    ): void {
        $emailKey = 'password_reset_'.$action.':email:'.$normalizedEmail;
        if ((int) Cache::get($emailKey, 0) >= $emailMax) {
            throw new PasswordResetException(
                'تم تجاوز عدد المحاولات. يرجى المحاولة لاحقاً.',
                429,
            );
        }

        if ($ip !== null && $ip !== '') {
            $ipKey = 'password_reset_'.$action.':ip:'.$ip;
            if ((int) Cache::get($ipKey, 0) >= $ipMax) {
                throw new PasswordResetException(
                    'تم تجاوز عدد المحاولات. يرجى المحاولة لاحقاً.',
                    429,
                );
            }
        }
    }

    protected function hitRateLimit(string $action, string $normalizedEmail, ?string $ip): void
    {
        $decayMinutes = match ($action) {
            'forgot' => 60,
            'verify' => 60,
            'resend' => 60,
            'reset' => 60,
            default => 60,
        };

        foreach ($this->rateLimitKeys($action, $normalizedEmail, $ip) as $key) {
            Cache::put(
                $key,
                (int) Cache::get($key, 0) + 1,
                now()->addMinutes($decayMinutes),
            );
        }
    }
}
