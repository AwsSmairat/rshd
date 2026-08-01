# RSHD Backend

منصة RSHD التعليمية — Backend (Laravel 11)

## المتطلبات

- PHP 8.2+
- Composer
- MySQL 8+
- Node.js (اختياري — لأصول Filament)

## التثبيت

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
```

عدّل `.env` لإعداد MySQL:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=rshd
DB_USERNAME=root
DB_PASSWORD=
```

## التشغيل

```bash
php artisan migrate:fresh --seed
php artisan serve
```

- **لوحة التحكم:** http://localhost:8000/admin
- **API:** http://localhost:8000/api/v1

## بيانات الدخول التجريبية

| الدور | البريد | كلمة المرور |
|-------|--------|-------------|
| Admin | admin@rshdacademy.com | password |
| Instructor | instructor@rshdacademy.com | password |
| Student | student@rshdacademy.com | password |

## البريد

في التطوير استخدم `MAIL_MAILER=log` (افتراضي) أو [Mailpit](https://github.com/axllent/mailpit).

### اختبار Email Verification OTP محلياً

1. تأكد من `.env`:
   ```env
   MAIL_MAILER=log
   ```
2. سجّل طالباً جديداً من التطبيق أو عبر API.
3. افتح `storage/logs/laravel.log` وابحث عن رمز OTP المكوّن من 6 أرقام.
4. أدخل الرمز في شاشة **تأكيد البريد الإلكتروني** في تطبيق Flutter.

لاحقاً في production يتم ضبط SMTP حقيقي.

## الأمان

راجع [SECURITY.md](SECURITY.md) لتفاصيل Composer audit و Laravel 11 advisories.

## اختبار API

- [API_CONTRACT.md](API_CONTRACT.md) — العقد الرسمي للـ API (موصى به لـ Flutter)
- [API_TESTING.md](API_TESTING.md) — أمثلة curl عملية

## API Authentication

```bash
# تسجيل طالب
curl -X POST http://localhost:8000/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Student","email":"new@example.com","password":"password","password_confirmation":"password"}'

# تسجيل الدخول
curl -X POST http://localhost:8000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email":"student@rshdacademy.com","password":"password"}'

# طلب محمي
curl http://localhost:8000/api/v1/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## هيكل المشروع

```
app/
├── Enums/           # Enums للحالات والأنواع
├── Filament/        # لوحة التحكم
├── Http/
│   ├── Controllers/Api/V1/
│   ├── Requests/Api/V1/
│   └── Resources/
├── Mail/
├── Models/
├── Policies/
└── Services/
```

## تعيين كلمة مرور المدرّس

رابط تعيين كلمة المرور: `/set-password?token=TOKEN&email=EMAIL`

يُرسل تلقائياً عند إنشاء مدرّس جديد من لوحة التحكم.
