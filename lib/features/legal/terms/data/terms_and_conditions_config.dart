/// إعدادات قابلة للتعديل للشروط والأحكام.
class TermsAndConditionsConfig {
  TermsAndConditionsConfig._();

  static const String termsVersion = '1.0';
  static const String termsLastUpdated = '2026/07/31';

  /// اسم الجهة القانونية — يُستبدل قبل النشر.
  static const String companyLegalName = 'RSHD';

  static const String supportEmail = 'admin@rshdacademy.com';
  static const String legalEmail = 'legal@rshdacademy.com';

  static const String supportPhone = '';
  static const String companyAddress = '';
  static const String supportHours =
      'الأحد – الخميس، 9:00 – 17:00 (توقيت عمّان)';

  /// الحد الأقصى للأجهزة — يُفضّل مزامنته مع إعدادات المنصة.
  static const int maximumAllowedDevices = 1;

  static const String refundRequestPeriod =
      'حسب السياسة المعتمدة من الإدارة';
  static const String refundProcessingPeriod =
      'حسب طريقة الدفع والسياسة المعتمدة';

  static const String governingLaw =
      'القوانين المعمول بها في الدولة التي تعتمدها الجهة المالكة للمنصة';
  static const String disputeJurisdiction =
      'جهة الاختصاص القضائي المعتمدة في النسخة المعتمدة من الشروط';
  static const String companyCountry = '';

  static const String supportEmailSubject = 'استفسار بخصوص شروط RSHD';
  static const String reportViolationSubject =
      'إبلاغ عن مخالفة — منصة RSHD';
}
