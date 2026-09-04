<?php

namespace App\Filament\Auth;

use Filament\Actions\Action;
use Filament\Forms\Components\Component;
use Filament\Forms\Components\Grid;
use Filament\Forms\Components\Placeholder;
use Filament\Pages\Auth\Login as BaseLogin;
use Illuminate\Contracts\Support\Htmlable;
use Illuminate\Support\HtmlString;

class Login extends BaseLogin
{
    protected static string $layout = 'filament.components.layout.auth-portal';

    public function getHeading(): string|Htmlable
    {
        return app()->getLocale() === 'en'
            ? 'Log in to your account'
            : 'الدخول إلى حسابك';
    }

    public function getSubheading(): ?string
    {
        return app()->getLocale() === 'en'
            ? 'RSHD Academy platform for instructors'
            : 'منصة رشاد الأكاديمية للمدرسين';
    }

    /**
     * @return array<int | string, string | \Filament\Forms\Form>
     */
    protected function getForms(): array
    {
        return [
            'form' => $this->form(
                $this->makeForm()
                    ->schema([
                        $this->getEmailFormComponent(),
                        $this->getPasswordFormComponent(),
                        Grid::make(['default' => 2])
                            ->schema([
                                $this->getForgotPasswordPlaceholder(),
                                $this->getRememberFormComponent(),
                            ]),
                    ])
                    ->statePath('data'),
            ),
        ];
    }

    protected function getEmailFormComponent(): Component
    {
        return parent::getEmailFormComponent()
            ->prefixIcon('heroicon-o-envelope')
            ->placeholder('example@domain.com');
    }

    protected function getPasswordFormComponent(): Component
    {
        return parent::getPasswordFormComponent()
            ->prefixIcon('heroicon-o-lock-closed')
            ->placeholder(
                app()->getLocale() === 'en'
                    ? 'Enter your password'
                    : 'أدخل كلمة المرور',
            )
            ->hint(null);
    }

    protected function getForgotPasswordPlaceholder(): Placeholder
    {
        $url = filament()->hasPasswordReset()
            ? (string) filament()->getRequestPasswordResetUrl()
            : '';
        $label = __('filament-panels::pages/auth/login.actions.request_password_reset.label');

        return Placeholder::make('forgotPassword')
            ->hiddenLabel()
            ->content(new HtmlString(
                $url === ''
                    ? ''
                    : '<a class="rshd-auth-forgot" href="'.e($url).'" tabindex="3">'.e($label).'</a>'
            ));
    }

    protected function getAuthenticateFormAction(): Action
    {
        return parent::getAuthenticateFormAction()
            ->icon('heroicon-m-arrow-left-on-rectangle');
    }
}
