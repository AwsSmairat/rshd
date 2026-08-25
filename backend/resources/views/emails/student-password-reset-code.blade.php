<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>رمز استعادة كلمة المرور</title>
</head>
<body style="font-family: Tahoma, Arial, sans-serif; background:#F6F1E7; padding:24px;">
    <div style="max-width:560px;margin:0 auto;background:#FFFDF8;border-radius:12px;padding:24px;border:1px solid #E5E7EB;">
        <h2 style="color:#0B1F3A;margin-top:0;">استعادة كلمة المرور</h2>
        <p style="color:#111827;">مرحباً {{ $user->name }}،</p>
        <p style="color:#111827;">
            طلبت استعادة كلمة المرور في {{ $platformName }}.
            استخدم الرمز التالي:
        </p>
        <p style="font-size:28px;font-weight:bold;letter-spacing:6px;color:#0B1F3A;text-align:center;">
            {{ $code }}
        </p>
        <p style="color:#6B7280;font-size:14px;">
            ينتهي هذا الرمز خلال {{ $expirySeconds }} ثانية.
            إذا لم تطلب استعادة كلمة المرور، تجاهل هذه الرسالة.
        </p>
    </div>
</body>
</html>
