<?php

namespace App\Providers\Filament;

use App\Filament\Auth\Login;
use App\Filament\Auth\RequestPasswordReset;
use App\Filament\Auth\ResetPassword;
use App\Http\Middleware\CheckPlatformMaintenance;
use App\Http\Middleware\RefreshAuthenticatedUser;
use App\Http\Middleware\SetFilamentLocale;
use App\Services\PlatformSettingsService;
use Filament\Facades\Filament;
use Filament\Http\Middleware\Authenticate;
use Filament\Http\Middleware\AuthenticateSession;
use Filament\Http\Middleware\DisableBladeIconComponents;
use Filament\Http\Middleware\DispatchServingFilamentEvent;
use Filament\Navigation\NavigationGroup;
use Filament\Panel;
use Filament\PanelProvider;
use Filament\Support\Colors\Color;
use Filament\View\PanelsRenderHook;
use Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse;
use Illuminate\Cookie\Middleware\EncryptCookies;
use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken;
use Illuminate\Routing\Middleware\SubstituteBindings;
use Illuminate\Session\Middleware\StartSession;
use Illuminate\Support\Facades\Blade;
use Illuminate\Support\HtmlString;
use Illuminate\View\Middleware\ShareErrorsFromSession;

class AdminPanelProvider extends PanelProvider
{
    public function panel(Panel $panel): Panel
    {
        $settings = app(PlatformSettingsService::class);

        return $panel
            ->default()
            ->id('admin')
            ->path('admin')
            ->login(Login::class)
            ->passwordReset(RequestPasswordReset::class, ResetPassword::class)
            ->brandName(fn (): string => $settings->platformName())
            ->brandLogo(function () use ($settings): string {
                $url = $settings->logoUrl() ?? asset('images/rshd_logo_no_bg.png');
                $version = (string) (@filemtime(public_path('images/rshd_logo_no_bg.png')) ?: 3);

                return $url.(str_contains($url, '?') ? '&' : '?').'v='.$version;
            })
            ->brandLogoHeight('3.4rem')
            ->favicon(fn (): string => $settings->faviconUrl().'?v=1')
            ->font('Cairo')
            ->colors([
                'primary' => Color::hex('#D6B56D'),
                'gray' => Color::Slate,
                'danger' => Color::hex('#991B1B'),
                'success' => Color::hex('#16A34A'),
                'warning' => Color::hex('#B88A32'),
                'info' => Color::hex('#102A4C'),
            ])
            ->darkMode(false)
            // Navigation runs along the top like a website header; on narrow
            // screens Filament folds it into the side drawer.
            ->topNavigation()
            ->navigationGroups(array_map(
                // Tag each group's menu: it opens detached at the end of the
                // page, where the stylesheet can no longer tell it apart.
                fn (string $label): NavigationGroup => NavigationGroup::make($label)
                    ->extraTopbarAttributes([
                        'x-init' => "\$nextTick(() => \$refs.panel?.classList.add('rshd-nav-panel'))",
                    ]),
                [
                    'التعليم',
                    'المستخدمون',
                    'التواصل',
                    'المحاسبة',
                    'النظام',
                    'الإدارة والتحليلات',
                    'الإعدادات والدعم',
                ],
            ))
            ->discoverResources(in: app_path('Filament/Resources'), for: 'App\\Filament\\Resources')
            ->discoverPages(in: app_path('Filament/Pages'), for: 'App\\Filament\\Pages')
            ->pages([])
            ->discoverWidgets(in: app_path('Filament/Widgets'), for: 'App\\Filament\\Widgets')
            ->widgets([])
            ->renderHook(
                PanelsRenderHook::STYLES_AFTER,
                fn (): HtmlString => new HtmlString(
                    '<link rel="stylesheet" href="'.e(asset('css/rshd-filament.css')).'?v=39">'.
                    '<link rel="stylesheet" href="'.e(asset('css/rshd-auth-portal.css')).'?v=6">'.
                    '<link rel="stylesheet" href="'.e(asset('css/rshd-motion.css')).'?v=2">'.
                    '<link rel="preconnect" href="https://fonts.googleapis.com">'.
                    '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>'.
                    '<link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800&display=swap" rel="stylesheet">'
                ),
            )
            ->renderHook(
                PanelsRenderHook::HEAD_END,
                function () use ($settings): HtmlString {
                    $favicon = e($settings->faviconUrl());
                    $icon16 = e(asset('images/favicon-16.png'));
                    $apple = e(asset('images/apple-touch-icon.png'));

                    return new HtmlString(
                        '<meta name="robots" content="noindex, nofollow, noarchive">'.
                        '<link rel="icon" type="image/png" sizes="32x32" href="'.$favicon.'?v=1">'.
                        '<link rel="icon" type="image/png" sizes="16x16" href="'.$icon16.'?v=1">'.
                        '<link rel="shortcut icon" href="'.$favicon.'?v=1">'.
                        '<link rel="apple-touch-icon" sizes="180x180" href="'.$apple.'?v=1">'
                    );
                },
            )
            ->renderHook(
                PanelsRenderHook::SIDEBAR_FOOTER,
                function (): HtmlString {
                    $user = auth()->user();

                    if ($user === null || ! $user->isInstructor()) {
                        return new HtmlString('');
                    }

                    $logoutUrl = e(Filament::getLogoutUrl());

                    return new HtmlString(
                        '<div class="rshd-sidebar-logout">'.
                        '<form method="POST" action="'.$logoutUrl.'">'.
                        csrf_field().
                        '<button type="submit" class="rshd-sidebar-logout__btn">'.
                        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" width="18" height="18">'.
                        '<path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0 0 13.5 3h-6A2.25 2.25 0 0 0 5.25 5.25v13.5A2.25 2.25 0 0 0 7.5 21h6a2.25 2.25 0 0 0 2.25-2.25V15M12 9l3 3m0 0-3 3m3-3H3" />'.
                        '</svg>'.
                        '<span>تسجيل الخروج</span>'.
                        '</button>'.
                        '</form>'.
                        '</div>'
                    );
                },
            )
            ->renderHook(
                PanelsRenderHook::SIDEBAR_NAV_START,
                fn (): HtmlString => new HtmlString(
                    '<div class="rshd-sidebar-brand-caption" style="padding:0 1rem 0.85rem;color:rgba(214,181,109,.8);font-size:.75rem;font-weight:600;">'
                    .e($settings->platformSubtitle())
                    .'</div>'
                ),
            )
            ->renderHook(
                // The curtain for page transitions and the first-visit intro.
                // It comes first in the body so a page reached from the menu
                // opens already covered (see public/js/rshd-motion.js).
                PanelsRenderHook::BODY_START,
                fn (): HtmlString => new HtmlString(Blade::render(
                    '<x-rshd-curtain :logo="$logo" :intro="$intro" intro-title="RSHD" :intro-tagline="$tagline" />',
                    [
                        'logo' => $settings->logoUrl() ?? asset('images/rshd_logo_no_bg.png'),
                        // The login screen greets a first visit with the intro.
                        'intro' => request()->routeIs('filament.admin.auth.login'),
                        'tagline' => $settings->platformSubtitle(),
                    ],
                )),
            )
            ->renderHook(
                PanelsRenderHook::SCRIPTS_AFTER,
                fn (): HtmlString => new HtmlString(
                    '<script src="'.e(asset('js/rshd-filament-menus.js')).'?v=3"></script>'.
                    '<script src="'.e(asset('js/rshd-motion.js')).'?v=2"></script>'
                ),
            )
            ->middleware([
                EncryptCookies::class,
                AddQueuedCookiesToResponse::class,
                StartSession::class,
                AuthenticateSession::class,
                ShareErrorsFromSession::class,
                VerifyCsrfToken::class,
                SubstituteBindings::class,
                DisableBladeIconComponents::class,
                DispatchServingFilamentEvent::class,
                CheckPlatformMaintenance::class,
                SetFilamentLocale::class,
                RefreshAuthenticatedUser::class,
            ])
            ->authMiddleware([
                Authenticate::class,
            ]);
    }
}
