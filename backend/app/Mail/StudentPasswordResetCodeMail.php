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

    public function __construct(
        public User $user,
        #[\SensitiveParameter] public string $code,
        public int $expirySeconds,
    ) {}

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
                'expirySeconds' => $this->expirySeconds,
            ]);
    }
}
