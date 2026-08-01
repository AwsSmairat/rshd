<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $platformName }} Email Verification</title>
</head>
<body style="margin:0;padding:0;background:#F6F1E7;font-family:Tahoma,Arial,sans-serif;color:#111827;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#F6F1E7;padding:24px 0;">
    <tr>
        <td align="center">
            <table width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background:#FFFDF8;border:1px solid #E5E7EB;border-radius:16px;overflow:hidden;">
                <tr>
                    <td style="background:#0B1F3A;padding:20px 24px;">
                        <h1 style="margin:0;color:#D6B56D;font-size:20px;">{{ $platformName }}</h1>
                    </td>
                </tr>
                <tr>
                    <td style="padding:24px;">
                        <p style="margin:0 0 12px;font-size:16px;">مرحباً {{ $user->name }},</p>
                        <p style="margin:0 0 16px;font-size:15px;line-height:1.7;">
                            رمز تأكيد بريدك في منصة {{ $platformName }} هو:
                        </p>
                        <p style="margin:0 0 16px;text-align:center;font-size:32px;font-weight:700;letter-spacing:6px;color:#0B1F3A;">
                            {{ $code }}
                        </p>
                        <p style="margin:0 0 8px;font-size:14px;color:#6B7280;">
                            ينتهي الرمز خلال {{ $expiryMinutes }} دقيقة.
                        </p>
                        <p style="margin:0;font-size:14px;color:#6B7280;">
                            Your {{ $platformName }} email verification code is: <strong>{{ $code }}</strong>. It expires in {{ $expiryMinutes }} minutes.
                        </p>
                        <hr style="margin:20px 0;border:none;border-top:1px solid #E5E7EB;">
                        <p style="margin:0;font-size:13px;color:#6B7280;">
                            إذا لم تقم بإنشاء حساب، تجاهل هذه الرسالة.
                        </p>
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>
