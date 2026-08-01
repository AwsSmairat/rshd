<?php

namespace App\Mail;

use App\Models\User;
use App\Services\InstructorInvitationService;
use App\Services\PlatformSettingsService;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class InstructorInvitationMail extends Mailable
{
    use Queueable, SerializesModels;

    public int $expiryHours;

    public string $platformName;

    public function __construct(
        public User $instructor,
        public string $token,
    ) {
        $settings = app(PlatformSettingsService::class);
        $this->expiryHours = app(InstructorInvitationService::class)->invitationExpiryHours();
        $this->platformName = $settings->platformName();
    }

    public function build(): self
    {
        return $this
            ->subject('تم إنشاء حسابك كمدرّس في منصة '.$this->platformName)
            ->markdown('emails.instructor-invitation', [
                'instructor' => $this->instructor,
                'setPasswordUrl' => $this->setPasswordUrl(),
                'expiryHours' => $this->expiryHours,
                'platformName' => $this->platformName,
            ]);
    }

    public function setPasswordUrl(): string
    {
        return config('app.url').'/set-password?token='.urlencode($this->token).'&email='.urlencode($this->instructor->email);
    }
}
