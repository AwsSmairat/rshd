<?php

namespace App\Filament\Auth;

use Filament\Pages\Auth\PasswordReset\RequestPasswordReset as BaseRequestPasswordReset;

class RequestPasswordReset extends BaseRequestPasswordReset
{
    protected static string $layout = 'filament.components.layout.auth-portal';

    public function getSubheading(): ?string
    {
        return app()->getLocale() === 'en'
            ? 'Enter your email and we will send a reset link.'
            : 'أدخل بريدك الإلكتروني وسنرسل رابط إعادة التعيين.';
    }
}
