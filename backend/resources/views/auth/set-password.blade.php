<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>تعيين كلمة المرور — {{ $platformName }}</title>
    <link rel="icon" type="image/png" href="{{ $faviconUrl }}">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --navy: #0B1F3A;
            --navy-2: #102A4C;
            --gold: #D6B56D;
            --dark-gold: #B88A32;
            --ivory: #F6F1E7;
            --card: #FFFDF8;
            --text: #111827;
            --muted: #6B7280;
            --border: #E5E7EB;
            --danger: #991B1B;
            --danger-bg: #FEF2F2;
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            min-height: 100vh;
            font-family: "Cairo", sans-serif;
            color: var(--text);
            background:
                radial-gradient(circle at 12% 10%, rgba(214, 181, 109, 0.22), transparent 32%),
                radial-gradient(circle at 88% 92%, rgba(16, 42, 76, 0.16), transparent 36%),
                linear-gradient(180deg, var(--ivory) 0%, #fff 100%);
        }

        .page {
            min-height: 100vh;
            display: grid;
            place-items: center;
            padding: 1.5rem 1rem 2rem;
        }

        .shell {
            width: min(100%, 28.5rem);
        }

        .brand {
            text-align: center;
            margin-bottom: 1.15rem;
        }

        .brand img {
            display: block;
            height: 5.5rem;
            width: auto;
            margin: 0 auto 0.65rem;
            object-fit: contain;
        }

        .brand p {
            margin: 0;
            color: var(--dark-gold);
            font-size: 0.82rem;
            font-weight: 700;
        }

        .card {
            background: var(--card);
            border: 1px solid rgba(214, 181, 109, 0.28);
            border-radius: 1.35rem;
            box-shadow: 0 22px 48px rgba(11, 31, 58, 0.1);
            overflow: hidden;
        }

        .card__header {
            padding: 1.35rem 1.4rem 1rem;
            background: linear-gradient(135deg, var(--navy) 0%, var(--navy-2) 100%);
            color: #fff;
            position: relative;
        }

        .card__header::after {
            content: "";
            position: absolute;
            inset-inline-end: -1.5rem;
            top: -1.5rem;
            width: 7rem;
            height: 7rem;
            border-radius: 999px;
            background: radial-gradient(circle, rgba(214, 181, 109, 0.28), transparent 68%);
            pointer-events: none;
        }

        .card__header h1 {
            margin: 0;
            font-size: 1.28rem;
            font-weight: 800;
        }

        .card__header p {
            margin: 0.4rem 0 0;
            color: rgba(255, 255, 255, 0.78);
            font-size: 0.9rem;
            line-height: 1.7;
        }

        .card__body {
            padding: 1.25rem 1.4rem 1.45rem;
        }

        .email-chip {
            display: flex;
            align-items: center;
            gap: 0.7rem;
            margin-bottom: 1.1rem;
            padding: 0.75rem 0.85rem;
            border-radius: 0.9rem;
            background: rgba(11, 31, 58, 0.04);
            border: 1px solid var(--border);
        }

        .email-chip strong {
            display: block;
            font-size: 0.72rem;
            color: var(--muted);
            font-weight: 700;
        }

        .email-chip span {
            display: block;
            font-size: 0.92rem;
            font-weight: 700;
            color: var(--navy);
            direction: ltr;
            text-align: right;
            word-break: break-all;
        }

        .alert {
            margin: 0 0 1rem;
            padding: 0.8rem 0.9rem;
            border-radius: 0.85rem;
            background: var(--danger-bg);
            color: var(--danger);
            border: 1px solid rgba(153, 27, 27, 0.16);
            font-size: 0.86rem;
            line-height: 1.7;
        }

        .alert ul {
            margin: 0;
            padding: 0 1rem 0 0;
        }

        .field {
            margin-bottom: 0.95rem;
        }

        .field label {
            display: block;
            margin-bottom: 0.4rem;
            font-size: 0.86rem;
            font-weight: 700;
            color: var(--navy);
        }

        .input-wrap {
            position: relative;
        }

        .input-wrap input {
            width: 100%;
            height: 2.85rem;
            padding: 0 2.7rem 0 0.9rem;
            border: 1px solid var(--border);
            border-radius: 0.85rem;
            background: #fff;
            font: inherit;
            font-size: 0.95rem;
            color: var(--text);
        }

        .input-wrap input:focus {
            outline: none;
            border-color: var(--gold);
            box-shadow: 0 0 0 3px rgba(214, 181, 109, 0.22);
        }

        .toggle-visibility {
            position: absolute;
            inset-inline-start: 0.35rem;
            top: 50%;
            transform: translateY(-50%);
            width: 2.1rem;
            height: 2.1rem;
            border: 0;
            background: transparent;
            color: var(--muted);
            cursor: pointer;
            border-radius: 0.55rem;
        }

        .toggle-visibility:hover {
            background: rgba(11, 31, 58, 0.05);
            color: var(--navy);
        }

        .hints {
            margin: 0 0 1.15rem;
            padding: 0.75rem 0.9rem;
            border-radius: 0.85rem;
            background: rgba(214, 181, 109, 0.1);
            border: 1px solid rgba(214, 181, 109, 0.22);
        }

        .hints p {
            margin: 0 0 0.4rem;
            font-size: 0.78rem;
            font-weight: 800;
            color: var(--navy);
        }

        .hints ul {
            margin: 0;
            padding: 0 1rem 0 0;
            color: var(--muted);
            font-size: 0.8rem;
            line-height: 1.7;
        }

        .submit {
            width: 100%;
            height: 2.95rem;
            border: 0;
            border-radius: 0.9rem;
            background: linear-gradient(135deg, var(--gold), var(--dark-gold));
            color: var(--navy);
            font: inherit;
            font-size: 0.98rem;
            font-weight: 800;
            cursor: pointer;
            box-shadow: 0 10px 22px rgba(184, 138, 50, 0.22);
        }

        .submit:hover {
            filter: brightness(1.03);
        }

        .footer {
            margin-top: 1rem;
            text-align: center;
        }

        .footer a {
            color: var(--navy);
            font-weight: 700;
            font-size: 0.88rem;
            text-decoration: none;
        }

        .footer a:hover {
            color: var(--dark-gold);
        }

        .empty-state {
            text-align: center;
            padding: 0.4rem 0 0.2rem;
        }

        .empty-state h2 {
            margin: 0 0 0.45rem;
            color: var(--navy);
            font-size: 1.05rem;
        }

        .empty-state p {
            margin: 0 0 1.1rem;
            color: var(--muted);
            line-height: 1.8;
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <main class="page">
        <div class="shell">
            <div class="brand">
                <img src="{{ $logoUrl }}" alt="{{ $platformName }}">
                <p>{{ $platformSubtitle }}</p>
            </div>

            <section class="card">
                <header class="card__header">
                    <h1>تعيين كلمة المرور</h1>
                    <p>أنشئ كلمة مرور لحساب المدرّس ثم سجّل الدخول إلى لوحة {{ $platformName }}.</p>
                </header>

                <div class="card__body">
                    @if (! $tokenValid)
                        <div class="empty-state">
                            <h2>الرابط غير صالح</h2>
                            <p>رابط تعيين كلمة المرور غير صالح أو منتهي الصلاحية. اطلب دعوة جديدة من الإدارة ثم أعد المحاولة.</p>
                            <a class="submit" href="{{ $loginUrl }}" style="display:inline-flex;align-items:center;justify-content:center;width:auto;padding:0 1.3rem;text-decoration:none;">العودة لتسجيل الدخول</a>
                        </div>
                    @else
                        <div class="email-chip">
                            <div>
                                <strong>حساب المدرّس</strong>
                                <span>{{ $email }}</span>
                            </div>
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
                                <label for="password">كلمة المرور الجديدة</label>
                                <div class="input-wrap">
                                    <input
                                        type="password"
                                        id="password"
                                        name="password"
                                        required
                                        minlength="8"
                                        autocomplete="new-password"
                                    >
                                    <button class="toggle-visibility" type="button" data-target="password" aria-label="إظهار كلمة المرور">
                                        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8">
                                            <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12s3.75-6.75 9.75-6.75S21.75 12 21.75 12s-3.75 6.75-9.75 6.75S2.25 12 2.25 12Z"/>
                                            <circle cx="12" cy="12" r="3"/>
                                        </svg>
                                    </button>
                                </div>
                            </div>

                            <div class="field">
                                <label for="password_confirmation">تأكيد كلمة المرور</label>
                                <div class="input-wrap">
                                    <input
                                        type="password"
                                        id="password_confirmation"
                                        name="password_confirmation"
                                        required
                                        minlength="8"
                                        autocomplete="new-password"
                                    >
                                    <button class="toggle-visibility" type="button" data-target="password_confirmation" aria-label="إظهار تأكيد كلمة المرور">
                                        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8">
                                            <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12s3.75-6.75 9.75-6.75S21.75 12 21.75 12s-3.75 6.75-9.75 6.75S2.25 12 2.25 12Z"/>
                                            <circle cx="12" cy="12" r="3"/>
                                        </svg>
                                    </button>
                                </div>
                            </div>

                            @if (count($passwordHints))
                                <div class="hints">
                                    <p>شروط كلمة المرور</p>
                                    <ul>
                                        @foreach ($passwordHints as $hint)
                                            <li>{{ $hint }}</li>
                                        @endforeach
                                    </ul>
                                </div>
                            @endif

                            <button class="submit" type="submit">حفظ كلمة المرور</button>
                        </form>

                        <div class="footer">
                            <a href="{{ $loginUrl }}">العودة لتسجيل الدخول</a>
                        </div>
                    @endif
                </div>
            </section>
        </div>
    </main>

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
