<?php

namespace App\Services;

use App\Enums\UserStatus;
use App\Exceptions\EmailVerificationException;
use App\Mail\StudentEmailVerificationCodeMail;
use App\Models\StudentEmailVerificationCode;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

class StudentEmailVerificationService
{
    public function __construct(
        protected PlatformSettingsService $settings,
    ) {}

    public function sendCode(User $user): void
    {
        if (! $this->settings->emailVerificationRequired()) {
            return;
        }

        StudentEmailVerificationCode::query()
            ->where('user_id', $user->id)
            ->whereNull('used_at')
            ->update(['used_at' => now()]);

        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $expiryMinutes = max(1, $this->settings->integer('otp_expiry_minutes', 10, 'registration'));

        StudentEmailVerificationCode::query()->create([
            'user_id' => $user->id,
            'email' => $user->email,
            'code_hash' => Hash::make($code),
            'expires_at' => now()->addMinutes($expiryMinutes),
            'attempts' => 0,
        ]);

        if (! $this->settings->enabled('otp_email_enabled', 'email')) {
            return;
        }

        $this->settings->applyMailPreferences();
        Mail::to($user->email)->send(new StudentEmailVerificationCodeMail($user, $code));
    }

    public function verifyCode(User $user, string $code): bool
    {
        if (! $this->settings->emailVerificationRequired()) {
            $user->update([
                'email_verified_at' => now(),
                'status' => UserStatus::Active,
            ]);

            return true;
        }

        $record = StudentEmailVerificationCode::query()
            ->where('user_id', $user->id)
            ->whereNull('used_at')
            ->where('expires_at', '>', now())
            ->latest('id')
            ->first();

        if ($record === null) {
            throw new EmailVerificationException('انتهت صلاحية الرمز أو غير موجود');
        }

        $maxAttempts = max(1, $this->settings->integer('max_otp_attempts', 5, 'registration'));
        if ($record->attempts >= $maxAttempts) {
            throw new EmailVerificationException('تم تجاوز عدد المحاولات');
        }

        if (! Hash::check($code, $record->code_hash)) {
            $record->increment('attempts');

            throw new EmailVerificationException('الرمز غير صحيح');
        }

        $record->update(['used_at' => now()]);

        $user->update([
            'email_verified_at' => now(),
            'status' => UserStatus::Active,
        ]);

        return true;
    }

    public function resendCode(User $user): void
    {
        if (! $this->settings->emailVerificationRequired()) {
            return;
        }

        $cooldown = max(15, $this->settings->integer('otp_resend_cooldown_seconds', 60, 'registration'));

        $latest = StudentEmailVerificationCode::query()
            ->where('user_id', $user->id)
            ->latest('id')
            ->first();

        if ($latest !== null && $latest->created_at->gt(now()->subSeconds($cooldown))) {
            throw new EmailVerificationException(
                "يرجى الانتظار {$cooldown} ثانية قبل إعادة إرسال الرمز",
                429,
            );
        }

        $this->sendCode($user);
    }
}
