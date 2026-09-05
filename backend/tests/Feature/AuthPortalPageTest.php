<?php

namespace Tests\Feature;

use App\Support\AuthPortal;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthPortalPageTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_login_uses_rshd_portal_layout(): void
    {
        $this->get('/admin/login')
            ->assertOk()
            ->assertSee('بوابة خاصة بالمدرسين', false)
            ->assertSee('الدخول إلى حسابك', false)
            ->assertSee('منصة RSHD الأكاديمية للمدرسين', false)
            ->assertSee('هل أنت مدرس جديد؟', false)
            ->assertSee('التواصل عبر واتساب', false)
            ->assertSee('+962 799532264', false)
            ->assertSee('https://wa.me/962799532264', false)
            ->assertSee('rshdacademy@gmail.com', false)
            ->assertSee('mailto:rshdacademy@gmail.com', false)
            ->assertSee('نسيت كلمة المرور؟', false)
            ->assertSee('تذكرني', false)
            ->assertSee('تسجيل الدخول', false)
            ->assertSee('من إعداد شركة', false)
            ->assertSee('images/dollarix-logo.png', false)
            ->assertSee('https://www.instagram.com/dollarix.studio/', false)
            ->assertSee('@dollarix.studio', false)
            ->assertDontSee('www.dollarix.co', false)
            ->assertSee('التعليم يبدأ من هنا', false);
    }

    public function test_login_portal_is_arabic_only(): void
    {
        $this->get('/locale/en')->assertNotFound();

        $this->withSession(['filament_locale' => 'en'])
            ->get('/admin/login')
            ->assertOk()
            ->assertSee('بوابة خاصة بالمدرسين', false)
            ->assertSee('التعليم يبدأ من هنا', false)
            ->assertDontSee('Instructors & admin portal', false)
            ->assertDontSee('rshd-auth-portal__lang', false);
    }

    public function test_password_reset_request_uses_portal_layout(): void
    {
        $this->get('/admin/password-reset/request')
            ->assertOk()
            ->assertSee('بوابة خاصة بالمدرسين', false)
            ->assertSee('نسيت كلمة المرور؟', false)
            ->assertSee('من إعداد شركة', false)
            ->assertSee('images/dollarix-logo.png', false);
    }

    public function test_format_phone_displays_jordan_number(): void
    {
        $this->assertSame('+962 7 9953 2264', AuthPortal::formatPhone('0799532264'));
        $this->assertSame('https://wa.me/962799532264', AuthPortal::whatsappHref('+962 799532264'));
        $this->assertSame('https://wa.me/962799532264', AuthPortal::whatsappHref('0799532264'));
    }
}
