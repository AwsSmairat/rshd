/// إعدادات قابلة للتعديل لسياسة الخصوصية دون تغيير تصميم الصفحة.
class PrivacyPolicyConfig {
  PrivacyPolicyConfig._();

  /// تاريخ آخر تحديث للسياسة (YYYY/MM/DD).
  static const String lastUpdated = '2026/07/31';

  /// رقم إصدار سياسة الخصوصية.
  static const String version = '1.0';

  /// بريد الخصوصية — يُستبدل بالقيمة الرسمية قبل النشر.
  static const String privacyEmail = 'privacy@rshdacademy.com';

  /// بريد الدعم الافتراضي — يُستبدل عند توفره من إعدادات المنصة.
  static const String supportEmail = 'admin@rshdacademy.com';

  /// رقم الهاتف — اتركه فارغًا حتى تتوفر بيانات رسمية.
  static const String supportPhone = '';

  /// عنوان الشركة — اتركه فارغًا حتى تتوفر بيانات رسمية.
  static const String companyAddress = '';

  /// ساعات الدعم.
  static const String supportHours =
      'الأحد – الخميس، 9:00 – 17:00 (توقيت عمّان)';

  /// المدة المتوقعة لمعالجة طلب حذف الحساب (بالأيام) — قابلة للتخصيص.
  static const String accountDeletionProcessingDays = '30';

  /// عنوان رسالة البريد عند التواصل بخصوص الخصوصية.
  static const String privacyEmailSubject =
      'استفسار بخصوص خصوصية حساب RSHD';

  /// عنوان رسالة البريد عند الإبلاغ عن مشكلة.
  static const String reportIssueEmailSubject =
      'إبلاغ عن مشكلة خصوصية — حساب RSHD';
}
