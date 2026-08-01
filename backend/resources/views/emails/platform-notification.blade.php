<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>{{ $title }}</title>
</head>
<body style="margin:0;padding:24px;background:#F6F1E7;font-family:Tahoma,Arial,sans-serif;color:#111827;">
    <div style="max-width:520px;margin:0 auto;background:#FFFDF8;border:1px solid #E5E7EB;border-radius:16px;padding:24px;">
        <h1 style="margin:0 0 12px;font-size:18px;color:#0B1F3A;">{{ $title }}</h1>
        <p style="margin:0 0 8px;">مرحباً {{ $user->name }},</p>
        <p style="margin:0;line-height:1.7;">{{ $body }}</p>
    </div>
</body>
</html>
