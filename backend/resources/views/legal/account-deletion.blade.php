@extends('legal.layout')

@section('title', 'حذف حساب RSHD')
@section('description', 'طريقة حذف حساب RSHD والبيانات المرتبطة به من داخل التطبيق أو عبر طلب خارجي.')
@section('canonical', '/account-deletion')

@php
    $subject = rawurlencode('طلب حذف حساب RSHD');
    $body = rawurlencode("أرغب بطلب حذف حساب RSHD المرتبط بهذا البريد الإلكتروني.\nيرجى تأكيد استلام الطلب.");
    $mailto = $contactEmail !== '' ? 'mailto:'.$contactEmail.'?subject='.$subject.'&body='.$body : null;
@endphp

@section('content')
    <article class="legal-document">
        <header class="legal-hero">
            <span class="legal-kicker">إدارة الحساب والبيانات</span>
            <h1>حذف حساب RSHD</h1>
            <p>يمكنك بدء حذف حسابك من داخل تطبيق RSHD، أو إرسال طلب حذف من هذه الصفحة إذا لم يعد بإمكانك الوصول إلى التطبيق.</p>
        </header>

        <div class="legal-sections">
            <section class="legal-section">
                <h2>الحذف من داخل التطبيق</h2>
                <ul>
                    <li>افتح تطبيق RSHD وسجّل الدخول.</li>
                    <li>انتقل إلى الإعدادات ثم الخصوصية.</li>
                    <li>اختر «حذف الحساب».</li>
                    <li>أكّد الحذف وأدخل كلمة المرور.</li>
                    <li>اضغط «تأكيد حذف الحساب».</li>
                </ul>
                <p><strong>مهم:</strong> لا ترسل كلمة المرور أو رمز التحقق عبر البريد أو الدعم.</p>
            </section>

            <section class="legal-section">
                <h2>طلب الحذف بدون التطبيق</h2>
                <p>إذا لم تستطع الوصول إلى التطبيق، أرسل الطلب من البريد المرتبط بحساب RSHD حتى يمكن التحقق من ملكية الحساب.</p>

                @if ($mailto)
                    <p><a class="legal-action" href="{{ $mailto }}">إرسال طلب حذف الحساب</a></p>
                    <p>البريد المستخدم لاستقبال الطلبات: {{ $contactEmail }}</p>
                @else
                    <p>قناة طلب الحذف عبر البريد غير متاحة حاليًا.</p>
                @endif
            </section>

            <section class="legal-section">
                <h2>البيانات المرتبطة بالحساب</h2>
                <p>عند تنفيذ الحذف، يتم حذف الحساب والبيانات المرتبطة به التي لا يلزم الاحتفاظ بها، بما في ذلك بيانات الحساب ورموز الدخول والأجهزة وبيانات الاستخدام التعليمية وصورة الحساب وملفات تسليم الواجبات المخزنة للطالب.</p>
                <p>قد نحتفظ ببيانات محدودة لأسباب قانونية أو مالية أو أمنية أو لحل النزاعات، وفق سياسة الخصوصية.</p>
            </section>

            <section class="legal-section">
                <h2>مدة المعالجة</h2>
                <p>الحذف المؤكد من داخل التطبيق يبدأ مباشرة. أما الطلبات المرسلة عبر البريد فقد تتطلب التحقق والمعالجة خلال مدة تصل إلى 30 يوم عمل، أو حسب ما تقتضيه المتطلبات القانونية.</p>
            </section>

            <section class="legal-section">
                <h2>سياسة الخصوصية</h2>
                <p><a class="legal-text-link" href="{{ route('legal.privacy') }}">عرض سياسة الخصوصية</a></p>
            </section>
        </div>
    </article>
@endsection
