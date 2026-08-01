<?php

namespace App\Mail;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class PlatformNotificationMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public User $user,
        public string $title,
        public string $body,
    ) {}

    public function build(): self
    {
        return $this
            ->subject($this->title)
            ->view('emails.platform-notification', [
                'user' => $this->user,
                'title' => $this->title,
                'body' => $this->body,
            ]);
    }
}
