@php
    $portal = (object) \App\Support\AuthPortal::data();
    $siteUrl = rtrim(config("app.url"), "/");
    $loginUrl = url("/admin/login");
    $shareImage = asset("images/rshd_logo.png");
    $description = "منصة RSHD الأكاديمية — بيئة تعليمية رقمية لتنظيم المحتوى التعليمي وإدارة الطلاب، مع بوابة مخصصة للمدرسين والإدارة.";
    $schemaContext = "https:/". "/schema.org";
    $schema = [
        "@context" => $schemaContext,
        "@type" => "EducationalOrganization",
        "name" => $portal->platformName,
        "url" => $siteUrl,
        "logo" => $shareImage,
        "description" => $description,
        "email" => $portal->email,
        "telephone" => $portal->phoneDisplay,
    ];
@endphp
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>RSHD | منصة تعليمية أكاديمية</title>
    <meta name="description" content="{{ $description }}">
    <meta name="robots" content="index, follow, max-image-preview:large">
    <meta name="theme-color" content="#F5F2EA">

    <link rel="canonical" href="{{ $siteUrl }}/">
    <link rel="icon" type="image/png" href="{{ $portal->faviconUrl }}">
    <link rel="apple-touch-icon" href="{{ asset("images/apple-touch-icon.png") }}">

    <meta property="og:type" content="website">
    <meta property="og:locale" content="ar_JO">
    <meta property="og:site_name" content="RSHD">
    <meta property="og:title" content="RSHD | منصة تعليمية أكاديمية">
    <meta property="og:description" content="{{ $description }}">
    <meta property="og:url" content="{{ $siteUrl }}/">
    <meta property="og:image" content="{{ $shareImage }}">

    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="RSHD | منصة تعليمية أكاديمية">
    <meta name="twitter:description" content="{{ $description }}">
    <meta name="twitter:image" content="{{ $shareImage }}">

    <link rel="preconnect" href="//fonts.googleapis.com">
    <link rel="preconnect" href="//fonts.gstatic.com" crossorigin>
    <link href="//fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ asset("css/rshd-home.css") }}?v=1">

    <script type="application/ld+json">{!! json_encode($schema, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) !!}</script>
</head>
<body>
    <div class="home-shell">
        <header class="site-header">
            <a class="brand" href="/" aria-label="RSHD">
                <img src="{{ $portal->logoUrl }}" alt="{{ $portal->platformName }}">
                <span>
                    <strong>RSHD</strong>
                    <small>المنصة الأكاديمية</small>
                </span>
            </a>

            <a class="header-login" href="{{ $loginUrl }}">تسجيل دخول المدرسين والإدارة</a>
        </header>

        <main>
            <section class="hero">
                <div class="hero-copy">
                    <span class="eyebrow">منصة RSHD الأكاديمية</span>

                    <h1>التعليم يبدأ من هنا</h1>

                    <p>
                        بيئة تعليمية رقمية تساعد على تنظيم المحتوى التعليمي وإدارة الطلاب،
                        وتوفر للمدرسين والإدارة مساحة موحدة وواضحة لإدارة العملية الأكاديمية.
                    </p>

                    <div class="hero-actions">
                        <a class="primary-action" href="{{ $loginUrl }}">الدخول إلى البوابة</a>
                        <a class="secondary-action" href="#contact">تواصل معنا</a>
                    </div>

                    <div class="trust-line">
                        <span></span>
                        بوابة مخصصة للمدرسين والإدارة
                    </div>
                </div>

                <div class="hero-card">
                    <div class="hero-logo-wrap">
                        <img src="{{ $portal->logoUrl }}" alt="شعار RSHD">
                    </div>
                    <h2>RSHD</h2>
                    <p>منصة أكاديمية مصممة لتجربة تعليمية أكثر تنظيمًا ووضوحًا.</p>

                    <div class="hero-points">
                        <div>
                            <strong>محتوى منظم</strong>
                            <span>إدارة المحتوى التعليمي من مكان واحد.</span>
                        </div>
                        <div>
                            <strong>إدارة أكاديمية</strong>
                            <span>أدوات واضحة للمدرسين والإدارة.</span>
                        </div>
                        <div>
                            <strong>تجربة موحدة</strong>
                            <span>تنظيم العملية التعليمية والتواصل مع الطلاب.</span>
                        </div>
                    </div>
                </div>
            </section>

            <section class="features" aria-labelledby="features-title">
                <div class="section-heading">
                    <span>منصة متكاملة</span>
                    <h2 id="features-title">كل ما يحتاجه الفريق الأكاديمي في مكان واحد</h2>
                </div>

                <div class="feature-grid">
                    <article>
                        <div class="feature-icon">01</div>
                        <h3>إدارة المحتوى التعليمي</h3>
                        <p>تنظيم المواد والمحتوى الأكاديمي بطريقة واضحة وسهلة للإدارة والمتابعة.</p>
                    </article>

                    <article>
                        <div class="feature-icon">02</div>
                        <h3>إدارة الطلاب</h3>
                        <p>تنظيم بيانات الطلاب ومتابعة العملية الأكاديمية من خلال النظام.</p>
                    </article>

                    <article>
                        <div class="feature-icon">03</div>
                        <h3>بوابة المدرسين والإدارة</h3>
                        <p>مساحة خاصة وآمنة لإدارة مهام المدرسين والإدارة الأكاديمية.</p>
                    </article>
                </div>
            </section>

            <section class="portal-cta">
                <div>
                    <span>للمدرسين والإدارة</span>
                    <h2>لديك حساب في RSHD؟</h2>
                    <p>ادخل إلى البوابة الخاصة بك لإدارة المحتوى والطلاب والمهام الأكاديمية.</p>
                </div>

                <a href="{{ $loginUrl }}">تسجيل الدخول</a>
            </section>

            <section class="contact" id="contact">
                <div class="section-heading">
                    <span>تواصل معنا</span>
                    <h2>نحن هنا للمساعدة</h2>
                    <p>للاستفسارات أو الانضمام إلى فريق التدريس يمكنك التواصل معنا مباشرة.</p>
                </div>

                <div class="contact-grid">
                    <a href="{{ $portal->phoneHref }}" target="_blank" rel="noopener noreferrer">
                        <span class="contact-label">واتساب</span>
                        <strong>{{ $portal->phoneDisplay }}</strong>
                    </a>

                    <a href="{{ $portal->emailHref }}">
                        <span class="contact-label">البريد الإلكتروني</span>
                        <strong>{{ $portal->email }}</strong>
                    </a>
                </div>
            </section>
        </main>

        <footer>
            <div class="footer-brand">
                <img src="{{ $portal->logoUrl }}" alt="RSHD">
                <div>
                    <strong>RSHD</strong>
                    <span>معًا لبناء مستقبل أفضل</span>
                </div>
            </div>

            <div class="footer-credit">
                <span>{{ $portal->footerCredit }}</span>
                @if ($portal->vendorLogoUrl)
                    <img src="{{ $portal->vendorLogoUrl }}" alt="{{ $portal->vendorName }}">
                @else
                    <strong>{{ $portal->vendorName }}</strong>
                @endif
            </div>

            <p>{{ $portal->copyright }}</p>
        </footer>
    </div>
</body>
</html>
