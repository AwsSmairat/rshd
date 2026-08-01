<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>تعيين كلمة المرور</title>
</head>
<body>
    <h1>تعيين كلمة المرور</h1>

    @if ($errors->any())
        <ul>
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    @endif

    <form method="POST" action="{{ url('/set-password') }}">
        @csrf

        <input type="hidden" name="email" value="{{ $email }}">
        <input type="hidden" name="token" value="{{ $token }}">

        <div>
            <label for="password">كلمة المرور</label>
            <input type="password" id="password" name="password" required minlength="8">
        </div>

        <div>
            <label for="password_confirmation">تأكيد كلمة المرور</label>
            <input type="password" id="password_confirmation" name="password_confirmation" required minlength="8">
        </div>

        <button type="submit">حفظ كلمة المرور</button>
    </form>
</body>
</html>
