@php
    $portal = (object) \App\Support\AuthPortal::data();
    $siteUrl = rtrim(config('app.url'), '/');
@endphp
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>@yield('title') | RSHD</title>
    <meta name="description" content="@yield('description')">
    <meta name="robots" content="index, follow, max-image-preview:large">
    <meta name="theme-color" content="#F5F2EA">

    <link rel="canonical" href="{{ $siteUrl }}@yield('canonical')">
    <link rel="icon" type="image/png" href="{{ $portal->faviconUrl }}">
    <link rel="apple-touch-icon" href="{{ asset('images/apple-touch-icon.png') }}">

    <link rel="preconnect" href="//fonts.googleapis.com">
    <link rel="preconnect" href="//fonts.gstatic.com" crossorigin>
    <link href="//fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ asset('css/rshd-legal.css') }}?v=1">
</head>
<body>
    <div class="legal-shell">
        <header class="legal-header">
            <a class="legal-brand" href="{{ route('home') }}" aria-label="RSHD">
                <img src="{{ $portal->logoUrl }}" alt="{{ $portal->platformName }}">
                <span>
                    <strong>RSHD</strong>
                    <small>المنصة الأكاديمية</small>
                </span>
            </a>

            <nav class="legal-nav" aria-label="الروابط القانونية">
                <a href="{{ route('legal.privacy') }}">سياسة الخصوصية</a>
                <a href="{{ route('legal.terms') }}">الشروط والأحكام</a>
                <a href="{{ route('legal.account-deletion') }}">حذف الحساب</a>
            </nav>
        </header>

        <main class="legal-main">
            @yield('content')
        </main>

        <footer class="legal-footer">
            <div class="legal-footer-links">
                <a href="{{ route('home') }}">الرئيسية</a>
                <a href="{{ route('legal.privacy') }}">سياسة الخصوصية</a>
                <a href="{{ route('legal.terms') }}">الشروط والأحكام</a>
                <a href="{{ route('legal.account-deletion') }}">حذف الحساب</a>
            </div>

            <p>{{ $portal->copyright }}</p>
        </footer>
    </div>
</body>
</html>
