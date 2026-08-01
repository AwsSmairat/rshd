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
    public function show(Request $request, InstructorInvitationService $invitationService): View
    {
        $request->validate([
            'token' => 'required|string',
            'email' => 'required|email',
        ]);

        $email = $request->query('email');
        $token = $request->query('token');

        if (! $invitationService->validateToken($email, $token)) {
            abort(403, 'رابط تعيين كلمة المرور غير صالح أو منتهي الصلاحية.');
        }

        return view('auth.set-password', [
            'email' => $email,
            'token' => $token,
        ]);
    }

    public function store(
        Request $request,
        InstructorInvitationService $invitationService,
        PlatformSettingsService $settings,
    ): RedirectResponse {
        $validated = $request->validate([
            'email' => 'required|email',
            'token' => 'required|string',
            'password' => $settings->passwordRules(confirmed: true),
        ]);

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
}
