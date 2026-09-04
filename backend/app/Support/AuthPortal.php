<?php

namespace App\Support;

use App\Services\PlatformSettingsService;

class AuthPortal
{
    /**
     * @return array{
     *     locale: string,
     *     nextLocale: string,
     *     dir: string,
     *     isArabic: bool,
     *     platformName: string,
     *     logoUrl: string,
     *     faviconUrl: string,
     *     slogan: string,
     *     languageLabel: string,
     *     portalTitle: string,
     *     portalSubtitle: string,
     *     newTeacherTitle: string,
     *     newTeacherBody: string,
     *     whatsappLabel: string,
     *     emailLabel: string,
     *     quote: string,
     *     footerCredit: string,
     *     copyright: string,
     *     footerSlogan: string,
     *     phoneDisplay: string,
     *     phoneHref: string,
     *     email: string,
     *     emailHref: string,
     *     vendorName: string,
     *     vendorLogoUrl: ?string,
     *     vendorWebsiteUrl: string,
     *     vendorWebsiteLabel: string,
     *     vendorInstagramUrl: string,
     *     vendorInstagramHandle: string
     * }
     */
    public static function data(): array
    {
        $settings = app(PlatformSettingsService::class);
        $locale = session('filament_locale', 'ar');

        if (! in_array($locale, ['ar', 'en'], true)) {
            $locale = 'ar';
        }

        app()->setLocale($locale);
        $isArabic = $locale === 'ar';
        $copy = self::copy($locale);
        $phone = (string) config('auth_portal.contact.whatsapp', '');
        $phoneDisplay = (string) config('auth_portal.contact.whatsapp_display', '');
        $email = (string) config('auth_portal.contact.email', '');
        $logoUrl = $settings->logoUrl() ?? asset('images/rshd_logo_no_bg.png');
        $version = (string) (@filemtime(public_path('images/rshd_logo_no_bg.png')) ?: 3);
        $vendorLogo = public_path((string) config('auth_portal.vendor.logo'));

        return [
            'locale' => $locale,
            'nextLocale' => $isArabic ? 'en' : 'ar',
            'dir' => $isArabic ? 'rtl' : 'ltr',
            'isArabic' => $isArabic,
            'platformName' => $settings->platformName(),
            'logoUrl' => $logoUrl.(str_contains($logoUrl, '?') ? '&' : '?').'v='.$version,
            'faviconUrl' => $settings->faviconUrl().'?v=1',
            ...$copy,
            'phoneDisplay' => $phoneDisplay !== '' ? $phoneDisplay : (self::formatPhone($phone) ?: $copy['phoneFallback']),
            'phoneHref' => self::whatsappHref($phone),
            'email' => $email,
            'emailHref' => $email !== '' ? 'mailto:'.$email : '#',
            'vendorName' => (string) config('auth_portal.vendor.name', 'DOLLARIX'),
            'vendorLogoUrl' => is_file($vendorLogo) ? asset((string) config('auth_portal.vendor.logo')) : null,
            'vendorWebsiteUrl' => (string) config('auth_portal.vendor.website_url'),
            'vendorWebsiteLabel' => (string) config('auth_portal.vendor.website_label'),
            'vendorInstagramUrl' => (string) config('auth_portal.vendor.instagram_url'),
            'vendorInstagramHandle' => (string) config('auth_portal.vendor.instagram_handle'),
        ];
    }

    /**
     * @return array<string, string>
     */
    protected static function copy(string $locale): array
    {
        if ($locale === 'en') {
            return [
                'slogan' => 'Education starts here',
                'languageLabel' => 'English',
                'portalTitle' => 'Instructors & admin portal',
                'portalSubtitle' => 'A private workspace for instructors and administrators to manage courses, students, and academic content.',
                'newTeacherTitle' => 'Are you a new instructor?',
                'newTeacherBody' => 'Contact technical support to create your account and join the teaching team.',
                'whatsappLabel' => 'Contact via WhatsApp',
                'emailLabel' => 'Contact via email',
                'quote' => 'Together we build a more knowledgeable generation. Join the RSHD Academy instructors.',
                'footerCredit' => 'Prepared by DOLLARIX',
                'copyright' => 'All rights reserved © '.date('Y').' RSHD Academy',
                'footerSlogan' => 'Together for a better future',
                'phoneFallback' => 'Number coming soon',
            ];
        }

        return [
            'slogan' => 'التعليم يبدأ من هنا',
            'languageLabel' => 'العربية',
            'portalTitle' => 'بوابة خاصة بالمدرسين',
            'portalSubtitle' => 'هذه البوابة مخصصة للمدرسين والإدارة لإدارة المحتوى التعليمي والطلاب من مكان واحد.',
            'newTeacherTitle' => 'هل أنت مدرس جديد؟',
            'newTeacherBody' => 'تواصل مع الدعم الفني لإنشاء حسابك والانضمام إلى فريق التدريس.',
            'whatsappLabel' => 'التواصل عبر واتساب',
            'emailLabel' => 'التواصل عبر البريد الإلكتروني',
            'quote' => 'معاً نصنع جيلاً أكثر معرفة .. انضم إلى نخبة المدرسين في رشاد الأكاديمية',
            'footerCredit' => 'من إعداد شركة DOLLARIX',
            'copyright' => 'جميع الحقوق محفوظة © '.date('Y').' منصة رشاد الأكاديمية',
            'footerSlogan' => 'معاً لبناء مستقبل أفضل',
            'phoneFallback' => 'يُضاف الرقم لاحقاً',
        ];
    }

    public static function formatPhone(string $phone): string
    {
        $digits = preg_replace('/\D+/', '', $phone) ?? '';

        if ($digits === '') {
            return '';
        }

        if (str_starts_with($digits, '00962')) {
            $digits = substr($digits, 2);
        }

        if (str_starts_with($digits, '0') && strlen($digits) === 10) {
            $digits = '962'.substr($digits, 1);
        }

        if (str_starts_with($digits, '962') && strlen($digits) >= 11) {
            return '+962 '.substr($digits, 3, 1).' '.substr($digits, 4, 4).' '.substr($digits, 8);
        }

        return $phone;
    }

    public static function whatsappHref(string $phone): string
    {
        $digits = preg_replace('/\D+/', '', $phone) ?? '';

        if ($digits === '') {
            return '#';
        }

        if (str_starts_with($digits, '0')) {
            $digits = '962'.substr($digits, 1);
        }

        return 'https://wa.me/'.$digits;
    }
}
