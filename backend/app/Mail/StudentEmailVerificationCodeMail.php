<?php

namespace App\Mail;

use App\Models\User;
use App\Services\PlatformSettingsService;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class StudentEmailVerificationCodeMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public User $user,
        public string $code,
        public int $expiryMinutes = 10,
        public string $platformName = 'RSHD',
    ) {
        $settings = app(PlatformSettingsService::class);
        $this->expiryMinutes = max(1, $settings->integer('otp_expiry_minutes', 10, 'registration'));
        $this->platformName = $settings->platformName();
    }

    public function build(): self
    {
        return $this
            ->subject($this->platformName.' — رمز تأكيد البريد')
            ->view('emails.student-email-verification-code', [
                'user' => $this->user,
                'code' => $this->code,
                'expiryMinutes' => $this->expiryMinutes,
                'platformName' => $this->platformName,
            ]);
    }
}
