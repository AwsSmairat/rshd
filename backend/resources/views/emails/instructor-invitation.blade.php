<x-mail::message>
# مرحباً {{ $instructor->name }}

تم إنشاء حسابك كمدرّس في منصة {{ $platformName }}.

يرجى الضغط على الزر أدناه لتعيين كلمة المرور وتفعيل حسابك. الرابط صالح لمدة {{ $expiryHours }} ساعة.

<x-mail::button :url="$setPasswordUrl">
تعيين كلمة المرور
</x-mail::button>

إذا لم تطلب إنشاء هذا الحساب، يمكنك تجاهل هذه الرسالة.

مع التحية،<br>
{{ $platformName }}
</x-mail::message>
