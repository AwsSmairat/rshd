<!DOCTYPE html>
<html lang="{{ $isArabic ? 'ar' : 'en' }}" dir="{{ $isArabic ? 'rtl' : 'ltr' }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex, nofollow, noarchive">
    <title>{{ $isArabic ? 'تعيين كلمة المرور' : 'Set password' }} — {{ $platformName }}</title>
    <link rel="icon" type="image/png" href="{{ $faviconUrl }}">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ asset('css/rshd-auth-portal.css') }}?v=6">
</head>
<body>
    <x-auth-portal-shell>
        <div class="rshd-auth-set-form">
            <img class="brand-mark" src="{{ $logoUrl }}" alt="{{ $platformName }}">
            <h2>{{ $isArabic ? 'تعيين كلمة المرور' : 'Set your password' }}</h2>
            <p class="sub">{{ $isArabic ? 'منصة RSHD الأكاديمية للمدرسين' : 'RSHD Academy platform for instructors' }}</p>

            @if (! $tokenValid)
                <div class="alert" role="alert">
                    {{ $isArabic
                        ? 'هذا الرابط غير صالح أو منتهي الصلاحية. اطلب دعوة جديدة من الإدارة ثم أعد المحاولة.'
                        : 'This password link is invalid or has expired. Ask admin to send a new invitation.' }}
                </div>
                <a class="submit" href="{{ $loginUrl }}">
                    {{ $isArabic ? 'العودة لتسجيل الدخول' : 'Back to sign in' }}
                </a>
            @else
                <div class="email-chip">
                    <strong>{{ $isArabic ? 'حساب المدرّس' : 'Instructor account' }}</strong>
                    <span dir="ltr">{{ $email }}</span>
                </div>

                @if ($errors->any())
                    <div class="alert" role="alert">
                        <ul>
                            @foreach ($errors->all() as $error)
                                <li>{{ $error }}</li>
                            @endforeach
                        </ul>
                    </div>
                @endif

                <form method="POST" action="{{ route('instructor.set-password.store') }}" novalidate>
                    @csrf
                    <input type="hidden" name="email" value="{{ $email }}">
                    <input type="hidden" name="token" value="{{ $token }}">

                    <div class="field">
                        <label for="password">{{ $isArabic ? 'كلمة المرور الجديدة' : 'New password' }}</label>
                        <div class="input-wrap">
                            <input type="password" id="password" name="password" required minlength="8" autocomplete="new-password">
                            <button class="toggle-visibility" type="button" data-target="password" aria-label="{{ $isArabic ? 'إظهار كلمة المرور' : 'Show password' }}">
                                <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12s3.75-6.75 9.75-6.75S21.75 12 21.75 12s-3.75 6.75-9.75 6.75S2.25 12 2.25 12Z"/>
                                    <circle cx="12" cy="12" r="3"/>
                                </svg>
                            </button>
                        </div>
                    </div>

                    <div class="field">
                        <label for="password_confirmation">{{ $isArabic ? 'تأكيد كلمة المرور' : 'Confirm password' }}</label>
                        <div class="input-wrap">
                            <input type="password" id="password_confirmation" name="password_confirmation" required minlength="8" autocomplete="new-password">
                            <button class="toggle-visibility" type="button" data-target="password_confirmation" aria-label="{{ $isArabic ? 'إظهار تأكيد كلمة المرور' : 'Show confirmation' }}">
                                <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12s3.75-6.75 9.75-6.75S21.75 12 21.75 12s-3.75 6.75-9.75 6.75S2.25 12 2.25 12Z"/>
                                    <circle cx="12" cy="12" r="3"/>
                                </svg>
                            </button>
                        </div>
                    </div>

                    @if (count($passwordHints))
                        <div class="hints">
                            <p>{{ $isArabic ? 'شروط كلمة المرور' : 'Password requirements' }}</p>
                            <ul>
                                @foreach ($passwordHints as $hint)
                                    <li>{{ $hint }}</li>
                                @endforeach
                            </ul>
                        </div>
                    @endif

                    <button class="submit" type="submit">{{ $isArabic ? 'حفظ كلمة المرور' : 'Save password' }}</button>
                </form>

                <a class="footer-link" href="{{ $loginUrl }}">{{ $isArabic ? 'العودة لتسجيل الدخول' : 'Back to sign in' }}</a>
            @endif
        </div>
    </x-auth-portal-shell>

    <script>
        document.querySelectorAll('.toggle-visibility').forEach((button) => {
            button.addEventListener('click', () => {
                const input = document.getElementById(button.dataset.target);
                if (!input) return;
                input.type = input.type === 'password' ? 'text' : 'password';
            });
        });
    </script>
</body>
</html>
