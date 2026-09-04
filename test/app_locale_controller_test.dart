import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/l10n/app_locale_controller.dart';
import 'package:rshd/core/l10n/app_strings.dart';

void main() {
  test('normalizes locale and maps direction', () {
    expect(normalizeAppLocale('en'), appLocaleEnglish);
    expect(normalizeAppLocale('ar'), appLocaleArabic);
    expect(normalizeAppLocale('fr'), appLocaleArabic);
    expect(localeFromPreference('en'), const Locale('en'));
    expect(textDirectionFromPreference('en'), TextDirection.ltr);
    expect(textDirectionFromPreference('ar'), TextDirection.rtl);
  });

  test('language picker labels switch with locale', () {
    const arabic = AppStrings(appLocaleArabic);
    const english = AppStrings(appLocaleEnglish);

    expect(arabic.language, 'اللغة');
    expect(english.language, 'Language');
    expect(arabic.languageLabel('ar'), 'العربية');
    expect(english.languageLabel('en'), 'English');
    expect(arabic.navHome, 'الرئيسية');
    expect(english.navHome, 'Home');
    expect(english.activatedCourses, 'Active courses');
    expect(english.academicDepartments, 'Academic departments');
    expect(english.departmentTitle('it'), 'Information Technology');
    expect(english.subjectCountLabel(1), '1 course');
    expect(english.subjectCountLabel(3), '3 courses');
  });

  test('translates leftover UI strings in English', () {
    const english = AppStrings(appLocaleEnglish);
    const arabic = AppStrings(appLocaleArabic);

    expect(english.t('تسجيل الدخول'), 'Sign in');
    expect(english.t('تعذر تحميل المواد'), 'Could not load courses');
    expect(english.t('لا توجد إشعارات حالياً'), 'No notifications right now');
    expect(english.t('تاريخ التسليم: 2026/01/01'), 'Due date: 2026/01/01');
    expect(english.t('السؤال 3 من 10'), 'Question 3 of 10');
    expect(english.t('3 فيديو'), '3 videos');
    expect(english.t('أساسيات الطب'), 'أساسيات الطب');
    expect(arabic.t('تسجيل الدخول'), 'تسجيل الدخول');
  });
}
