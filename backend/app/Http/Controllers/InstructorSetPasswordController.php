<?php

namespace App\Http\Controllers;

use App\Services\InstructorInvitationService;
use App\Services\PlatformSettingsService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;
use InvalidArgumentException;

class InstructorSetPasswordController extends Controller
{
    public function show(
        Request $request,
        InstructorInvitationService $invitationService,
        PlatformSettingsService $settings,
    ): View {
        $request->validate([
            'token' => 'required|string',
            'email' => 'required|email',
        ]);

        $email = (string) $request->query('email');
        $token = (string) $request->query('token');

        return view('auth.set-password', $this->viewData(
            $settings,
            $email,
            $token,
            $invitationService->validateToken($email, $token),
        ));
    }

    public function store(
        Request $request,
        InstructorInvitationService $invitationService,
        PlatformSettingsService $settings,
    ): RedirectResponse {
        $validated = $request->validate(
            [
                'email' => 'required|email',
                'token' => 'required|string',
                'password' => $settings->passwordRules(confirmed: true),
            ],
            [
                'password.required' => 'كلمة المرور مطلوبة.',
                'password.min' => 'يجب أن تكون كلمة المرور :min أحرف على الأقل.',
                'password.confirmed' => 'كلمتا المرور غير متطابقتين.',
                'password.regex' => 'كلمة المرور لا تستوفي شروط القوة المطلوبة.',
            ],
        );

        try {
            $invitationService->setPassword(
                $validated['email'],
                $validated['token'],
                $validated['password'],
            );
        } catch (InvalidArgumentException $exception) {
            return back()
                ->withInput($request->except('password', 'password_confirmation'))
                ->withErrors(['token' => $exception->getMessage()]);
        }

        return redirect('/admin/login')->with(
            'success',
            'تم تعيين كلمة المرور بنجاح. يمكنك تسجيل الدخول الآن.',
        );
    }

    /**
     * @return array{
     *     email: string,
     *     token: string,
     *     tokenValid: bool,
     *     platformName: string,
     *     platformSubtitle: string,
     *     logoUrl: string,
     *     faviconUrl: string,
     *     passwordHints: list<string>,
     *     loginUrl: string
     * }
     */
    protected function viewData(
        PlatformSettingsService $settings,
        string $email,
        string $token,
        bool $tokenValid,
    ): array {
        $logoUrl = $settings->logoUrl() ?? asset('images/rshd_logo_no_bg.png');
        $version = (string) (@filemtime(public_path('images/rshd_logo_no_bg.png')) ?: 3);

        return [
            'email' => $email,
            'token' => $token,
            'tokenValid' => $tokenValid,
            'platformName' => $settings->platformName(),
            'platformSubtitle' => $settings->platformSubtitle(),
            'logoUrl' => $logoUrl.(str_contains($logoUrl, '?') ? '&' : '?').'v='.$version,
            'faviconUrl' => $settings->faviconUrl().'?v=1',
            'passwordHints' => $this->passwordHints($settings),
            'loginUrl' => url('/admin/login'),
        ];
    }

    /**
     * @return list<string>
     */
    protected function passwordHints(PlatformSettingsService $settings): array
    {
        $hints = [
            $settings->integer('password_min_length', 8, 'security').' أحرف على الأقل',
        ];

        if ($settings->enabled('password_require_uppercase', 'security')) {
            $hints[] = 'حرف إنجليزي كبير واحد على الأقل';
        }

        if ($settings->enabled('password_require_number', 'security')) {
            $hints[] = 'رقم واحد على الأقل';
        }

        if ($settings->enabled('password_require_special', 'security')) {
            $hints[] = 'رمز خاص واحد على الأقل';
        }

        return $hints;
    }
}
