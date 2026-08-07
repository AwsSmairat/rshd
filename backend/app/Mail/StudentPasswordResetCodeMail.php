<?php

namespace App\Mail;

use App\Models\User;
use App\Services\PlatformSettingsService;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class StudentPasswordResetCodeMail extends Mailable
{
    use Queueable, SerializesModels;

    public int $expiryMinutes;

    public function __construct(
        public User $user,
        #[\SensitiveParameter] public string $code,
    ) {
        $settings = app(PlatformSettingsService::class);
        $this->expiryMinutes = max(1, $settings->integer('otp_expiry_minutes', 10, 'registration'));
    }

    public function build(): self
    {
        $platformName = app(PlatformSettingsService::class)->stringValue(
            'platform_name',
            'RSHD',
            'general',
        );

        return $this->subject("رمز استعادة كلمة المرور — {$platformName}")
            ->view('emails.student-password-reset-code', [
                'user' => $this->user,
                'code' => $this->code,
                'platformName' => $platformName,
                'expiryMinutes' => $this->expiryMinutes,
            ]);
    }
}
