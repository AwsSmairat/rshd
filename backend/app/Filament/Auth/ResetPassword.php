<?php

namespace App\Filament\Auth;

use Filament\Pages\Auth\PasswordReset\ResetPassword as BaseResetPassword;

class ResetPassword extends BaseResetPassword
{
    protected static string $layout = 'filament.components.layout.auth-portal';
}
