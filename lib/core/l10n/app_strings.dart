import 'package:flutter/material.dart';

import 'app_locale_controller.dart';
import 'ui_en.dart';

class AppStrings {
  const AppStrings(this.languageCode);

  final String languageCode;

  static AppStrings of(BuildContext context) => AppStringsScope.of(context);

  bool get isEnglish => languageCode == appLocaleEnglish;

  String _t(String ar, String en) => isEnglish ? en : ar;

  String t(String source) {
    if (source.isEmpty || !isEnglish) {
      return source;
    }
    final exact = kUiEnglish[source];
    if (exact != null) {
      return exact;
    }
    final questionProgress = RegExp(
      r'^السؤال (\d+) من (\d+)$',
    ).firstMatch(source);
    if (questionProgress != null) {
      return 'Question ${questionProgress[1]} of ${questionProgress[2]}';
    }
    final pageOf = RegExp(r'^الصفحة: (\d+) من (\d+)$').firstMatch(source);
    if (pageOf != null) {
      return 'Page: ${pageOf[1]} of ${pageOf[2]}';
    }
    final pageSlash = RegExp(r'^صفحة (\d+) من (\d+)$').firstMatch(source);
    if (pageSlash != null) {
      return 'Page ${pageSlash[1]} of ${pageSlash[2]}';
    }
    var out = source;
    for (final key in kUiEnglishKeysByLength) {
      if (!_isSafePartialKey(key)) {
        continue;
      }
      if (out.contains(key)) {
        out = out.replaceAll(key, kUiEnglish[key]!);
      }
    }
    return out;
  }

  bool _isSafePartialKey(String key) {
    if (key.length >= 24) {
      return true;
    }
    if (key.startsWith(' ') || key.endsWith(' ')) {
      return true;
    }
    if (key.endsWith(':') || key.endsWith(': ')) {
      return true;
    }
    if (key.startsWith('%')) {
      return true;
    }
    return false;
  }

  String get language => _t('اللغة', 'Language');
  String get arabic => _t('العربية', 'Arabic');
  String get english => 'English';
  String get appPreferences => _t('تفضيلات التطبيق', 'App preferences');
  String get appearance => _t('الوضع', 'Appearance');
  String get lightMode => _t('الوضع الفاتح', 'Light');
  String get darkMode => _t('الوضع الداكن', 'Dark');
  String get systemMode => _t('حسب النظام', 'System');
  String get fontSize => _t('حجم الخط', 'Font size');
  String get fontSmall => _t('صغير', 'Small');
  String get fontMedium => _t('متوسط', 'Medium');
  String get fontLarge => _t('كبير', 'Large');
  String get autoPlayVideo => _t('التشغيل التلقائي للفيديو', 'Autoplay videos');
  String get videoQuality => _t('جودة الفيديو', 'Video quality');
  String get qualityAuto => _t('تلقائية', 'Auto');
  String get qualityLow => _t('منخفضة', 'Low');
  String get qualityMedium => _t('متوسطة', 'Medium');
  String get qualityHigh => _t('عالية', 'High');
  String get saveWatchPosition =>
      _t('حفظ آخر موضع مشاهدة', 'Save last watch position');
  String get timezone => _t('المنطقة الزمنية', 'Time zone');

  String get profilePhoto => _t('الصورة الشخصية', 'Profile photo');
  String get changePhotoHint =>
      _t('يمكنك تغيير صورتك الشخصية', 'You can change your profile photo');
  String get changePhoto => _t('تغيير الصورة', 'Change photo');
  String get pickFromGallery => _t('اختيار من المعرض', 'Choose from gallery');
  String get takePhoto => _t('التقاط صورة', 'Take a photo');
  String get deletePhoto => _t('حذف الصورة', 'Delete photo');

  String get personalInfo => _t('المعلومات الشخصية', 'Personal information');
  String get edit => _t('تعديل', 'Edit');
  String get fullName => _t('الاسم الكامل', 'Full name');
  String get email => _t('البريد الإلكتروني', 'Email');
  String get phone => _t('رقم الهاتف', 'Phone number');
  String get birthDate => _t('تاريخ الميلاد', 'Date of birth');
  String get gender => _t('الجنس', 'Gender');
  String get country => _t('الدولة', 'Country');
  String get studentId => _t('الرقم التعريفي', 'Student ID');
  String get accountStatus => _t('حالة الحساب', 'Account status');
  String get male => _t('ذكر', 'Male');
  String get female => _t('أنثى', 'Female');
  String get statusActive => _t('نشط', 'Active');
  String get statusBlocked => _t('موقوف', 'Blocked');
  String get studentRole => _t('طالب', 'Student');

  String get securityPassword =>
      _t('الأمان وكلمة المرور', 'Security and password');
  String get changePassword => _t('تغيير كلمة المرور', 'Change password');
  String get sessionsDevices => _t('الجلسات والأجهزة', 'Sessions and devices');
  String get logoutAllDevices =>
      _t('تسجيل الخروج من جميع الأجهزة', 'Log out of all devices');
  String passwordLastUpdated(String date) =>
      _t('آخر تحديث لكلمة المرور: $date', 'Password last updated: $date');

  String get notifications => _t('الإشعارات', 'Notifications');
  String get enableAll => _t('تفعيل الكل', 'Enable all');
  String get disableAll => _t('تعطيل الكل', 'Disable all');
  String get notifyNewLessons =>
      _t('إشعارات الدروس الجديدة', 'New lesson notifications');
  String get notifyAssignments =>
      _t('إشعارات الواجبات', 'Assignment notifications');
  String get notifyAssignmentReminders =>
      _t('تذكير موعد تسليم الواجب', 'Assignment due reminders');
  String get notifyQuizzes => _t('إشعارات الاختبارات', 'Quiz notifications');
  String get notifyQuizReminders => _t('تذكير موعد الاختبار', 'Quiz reminders');
  String get notifyGrades => _t('إشعارات الدرجات', 'Grade notifications');
  String get notifyMessages => _t('إشعارات الرسائل', 'Message notifications');
  String get notifyAnnouncements =>
      _t('إشعارات الإعلانات', 'Announcement notifications');
  String get notifyPlatformUpdates => _t('تحديثات المنصة', 'Platform updates');
  String get sound => _t('الصوت', 'Sound');
  String get vibration => _t('الاهتزاز', 'Vibration');

  String get privacy => _t('الخصوصية', 'Privacy');
  String get whoCanSeeProfile =>
      _t('من يمكنه رؤية الملف', 'Who can see your profile');
  String get whoCanMessage => _t('من يمكنه مراسلتي', 'Who can message me');
  String get everyone => _t('الجميع', 'Everyone');
  String get teachersOnly => _t('المدرسون فقط', 'Teachers only');
  String get private => _t('خاص', 'Private');
  String get nobody => _t('لا أحد', 'Nobody');
  String get showActivityStatus =>
      _t('إظهار حالة النشاط', 'Show activity status');
  String get allowProfilePhotoUse =>
      _t('السماح باستخدام الصورة الشخصية', 'Allow using profile photo');

  String get supportAndInfo => _t('الدعم والمعلومات', 'Support and info');
  String get helpCenter => _t('مركز المساعدة', 'Help center');
  String get contactUs => _t('تواصل معنا', 'Contact us');
  String get terms => _t('الشروط والأحكام', 'Terms and conditions');
  String get privacyPolicy => _t('سياسة الخصوصية', 'Privacy policy');
  String aboutApp(String version) =>
      _t('حول التطبيق • $version', 'About the app • $version');
  String get aboutAppTitle => _t('حول التطبيق', 'About the app');
  String aboutAppMessage(String name, String version) =>
      _t('$name\nالإصدار: $version', '$name\nVersion: $version');

  String get logout => _t('تسجيل خروج', 'Log out');
  String get loggingOut => _t('جارٍ تسجيل الخروج...', 'Signing out...');
  String get logoutTitle => _t('تسجيل الخروج', 'Log out');
  String get logoutConfirm => _t(
    'هل أنت متأكد أنك تريد تسجيل الخروج؟',
    'Are you sure you want to log out?',
  );
  String get cancel => _t('إلغاء', 'Cancel');
  String get continueAction => _t('متابعة', 'Continue');
  String get ok => _t('حسناً', 'OK');
  String get back => _t('رجوع', 'Back');
  String get logoutAllTitle =>
      _t('تسجيل الخروج من جميع الأجهزة', 'Log out of all devices');
  String get logoutAllConfirm => _t(
    'سيتم إنهاء جميع الجلسات الأخرى. هل تريد المتابعة؟',
    'All other sessions will end. Do you want to continue?',
  );

  String get studentSettings => _t('إعدادات الطالب', 'Student settings');
  String get loadingSettings =>
      _t('جاري تحميل الإعدادات...', 'Loading settings...');
  String get failedSettings =>
      _t('تعذر تحميل الإعدادات', 'Could not load settings');

  String get navSubjects => _t('موادي', 'Courses');
  String get navAssignments => _t('واجباتي', 'Assignments');
  String get navHome => _t('الرئيسية', 'Home');
  String get navGrades => _t('درجاتي', 'Grades');
  String get navMore => _t('المزيد', 'More');
  String get navQuizzes => _t('اختباراتي', 'Quizzes');
  String get greetingHello => _t('مرحباً،', 'Hello,');
  String get homeSearchHint =>
      _t('ابحث عن مادة أو مدرّس...', 'Search a course or instructor...');
  String get suggestedForYou => _t('مقترح لك', 'Suggested for you');
  String get startLearningTitle =>
      _t('ابدأ رحلتك التعليمية', 'Start your learning journey');
  String get startLearningHint => _t(
    'لم تسجّل في أي مادة بعد. تصفّح المواد واختر ما يناسبك.',
    "You haven't joined a course yet. Browse and pick one.",
  );
  String get browseCourses => _t('تصفّح المواد', 'Browse courses');
  String get upcomingEmptyHint => _t(
    'ستظهر هنا الواجبات والاختبارات القادمة',
    'Upcoming assignments and quizzes will appear here',
  );
  String percentComplete(int percent) =>
      _t('$percent% مكتمل', '$percent% complete');
  String get myGrades => _t('درجاتي', 'My grades');
  String get announcementsShort => _t('الإعلانات', 'Announcements');
  String get supportShort => _t('الدعم الفني', 'Support');
  String get searchNoResults =>
      _t('لا توجد نتائج مطابقة', 'No matching results');
  String get navAccount => _t('حسابي', 'Account');

  String welcomePrefix(String name) => _t('مرحباً، $name', 'Welcome, $name');
  String get welcomeGreeting => _t('مرحباً، ', 'Welcome, ');
  String get continueLearningToday =>
      _t('تابع تعلمك اليوم', 'Continue learning today');
  String get profileTooltip => _t('الملف الشخصي', 'Profile');
  String get rshdStudentFallback => _t('طالب RSHD', 'RSHD student');
  String get loadingHome =>
      _t('تعذر تحميل الصفحة الرئيسية', 'Could not load the home page');
  String get unexpectedError => _t('حدث خطأ غير متوقع', 'Something went wrong');

  String get activatedCourses => _t('المواد المفعلة', 'Active courses');
  String get unsubmittedAssignments =>
      _t('واجبات غير مسلّمة', 'Unsubmitted assignments');
  String get availableQuizzes => _t('اختبارات متاحة', 'Available quizzes');

  String get quickShortcuts => _t('اختصارات سريعة', 'Quick shortcuts');
  String get lectures => _t('المحاضرات', 'Lectures');
  String get assignments => _t('الواجبات', 'Assignments');
  String get quizzes => _t('الاختبارات', 'Quizzes');
  String get viewAll => _t('عرض الكل >', 'View all >');

  String get academicDepartments =>
      _t('الأقسام الأكاديمية', 'Academic departments');
  String get informationTechnology =>
      _t('تكنولوجيا المعلومات', 'Information Technology');
  String get itDepartmentSubtitle => _t(
    'برمج، ابتكر، وكن جزءاً من مستقبل التقنية',
    'Code, create, and be part of the future of technology',
  );
  String get engineering => _t('الهندسة', 'Engineering');
  String get engineeringSubtitle => _t(
    'تعلم وطور مهاراتك الهندسية',
    'Build and grow your engineering skills',
  );
  String get medicine => _t('الطب', 'Medicine');
  String get medicineSubtitle => _t(
    'كل ما تحتاجه لدراستك في مجال الطب',
    'Everything you need for your medical studies',
  );
  String get otherSubjects => _t('مواد أخرى', 'Other courses');

  String get upcomingTasks => _t('المهام القادمة', 'Upcoming tasks');
  String get noUpcomingTasks =>
      _t('لا توجد مهام قادمة حالياً', 'No upcoming tasks right now');
  String get studyAssignment => _t('واجب دراسي', 'Assignment');
  String get quiz => _t('اختبار', 'Quiz');
  String get currentCourses => _t('موادي الحالية', 'My current courses');
  String get noActiveCourses =>
      _t('لا توجد مواد مفعلة حالياً', 'No active courses yet');
  String get continueWhereYouLeft =>
      _t('تابع من حيث توقفت', 'Continue where you left off');
  String get continueLearning => _t('متابعة التعلم', 'Continue learning');
  String get gradesSummary => _t('ملخص الدرجات', 'Grades summary');
  String get noGradesYet => _t('لا توجد درجات حالياً', 'No grades yet');
  String get average => _t('المتوسط', 'Average');
  String get highest => _t('الأعلى', 'Highest');
  String get noQuizzesYet =>
      _t('لا توجد اختبارات حالياً', 'No quizzes right now');
  String get announcementsLoadFailed =>
      _t('تعذر تحميل بعض الإعلانات', 'Some announcements could not be loaded');

  String get accountDetails => _t('بيانات الحساب', 'Account details');
  String get name => _t('الاسم', 'Name');
  String get role => _t('الدور', 'Role');
  String get accountCreatedAt => _t('تاريخ إنشاء الحساب', 'Account created');
  String get linkedDevice => _t('الجهاز المرتبط', 'Linked device');
  String get noLinkedDevice =>
      _t('لا يوجد جهاز مرتبط حالياً', 'No device is linked yet');
  String get deviceName => _t('اسم الجهاز', 'Device name');
  String get systemType => _t('نوع النظام', 'Platform');
  String get lastLogin => _t('آخر تسجيل دخول', 'Last login');
  String get linkedDeviceNotice => _t(
    'حسابك مرتبط بهذا الجهاز لحماية المحتوى التعليمي.',
    'Your account is linked to this device to protect educational content.',
  );
  String get loadingProfile =>
      _t('جاري تحميل الملف الشخصي...', 'Loading profile...');
  String get failedProfile =>
      _t('تعذر تحميل الملف الشخصي', 'Could not load profile');
  String get instructorRole => _t('مدرّس', 'Instructor');
  String get adminRole => _t('مدير', 'Admin');
  String get statusInactive => _t('غير نشط', 'Inactive');
  String get statusPending => _t('قيد الانتظار', 'Pending');

  String themeLabel(String theme) => switch (theme) {
    'dark' => darkMode,
    'system' => systemMode,
    _ => lightMode,
  };

  String fontLabel(String size) => switch (size) {
    'small' => fontSmall,
    'large' => fontLarge,
    _ => fontMedium,
  };

  String qualityLabel(String quality) => switch (quality) {
    'low' => qualityLow,
    'medium' => qualityMedium,
    'high' => qualityHigh,
    _ => qualityAuto,
  };

  String languageLabel(String language) =>
      language == appLocaleEnglish ? english : arabic;

  String genderLabel(String? gender) => switch (gender) {
    'male' => male,
    'female' => female,
    _ => '—',
  };

  String statusLabel(String status) => switch (status) {
    'active' => statusActive,
    'blocked' => statusBlocked,
    _ => status,
  };

  String visibilityLabel(String value) => switch (value) {
    'everyone' => everyone,
    'private' => private,
    _ => teachersOnly,
  };

  String messagingLabel(String value) => switch (value) {
    'everyone' => everyone,
    'nobody' => nobody,
    _ => teachersOnly,
  };

  String departmentTitle(String key) => switch (key) {
    'medicine' => medicine,
    'it' => informationTechnology,
    'engineering' => engineering,
    'general' => otherSubjects,
    _ => key,
  };

  String subjectCountLabel(int count) {
    if (isEnglish) {
      return count == 1 ? '1 course' : '$count courses';
    }
    if (count == 0) {
      return '0 مواد';
    }
    if (count == 1) {
      return '1 مادة';
    }
    if (count == 2) {
      return '2 مادتان';
    }
    if (count >= 3 && count <= 10) {
      return '$count مواد';
    }
    return '$count مادة';
  }

  String monthName(int month) {
    const ar = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    const en = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) {
      return '';
    }
    return (isEnglish ? en : ar)[month - 1];
  }

  String roleLabel(String role) => switch (role) {
    'student' => studentRole,
    'instructor' => instructorRole,
    'admin' => adminRole,
    _ => role,
  };

  String profileStatusLabel(String status) => switch (status) {
    'active' => statusActive,
    'inactive' => statusInactive,
    'pending' => statusPending,
    'blocked' => statusBlocked,
    _ => status,
  };

  // --- Login screen ---------------------------------------------------------

  String get emailFieldLabel => _t('البريد الإلكتروني', 'Email address');

  String get emailFieldHint => _t('you@example.com', 'you@example.com');

  String get passwordFieldLabel => _t('كلمة المرور', 'Password');

  String get passwordFieldHint => _t('أدخل كلمة المرور', 'Enter your password');

  String get orDivider => _t('أو', 'OR');

  String get continueWithGoogle =>
      _t('المتابعة عبر Google', 'Continue with Google');

  String get continueWithApple =>
      _t('المتابعة عبر Apple', 'Continue with Apple');

  String get comingSoonNotice => _t(
    'قريبًا — هذه الميزة ستتوفر قريبًا',
    'Coming soon — This feature will be available soon',
  );

  String get phoneOptionalLabel =>
      _t('رقم الهاتف (اختياري)', 'Phone number (optional)');

  String get confirmPasswordLabel =>
      _t('تأكيد كلمة المرور', 'Confirm password');

  String get noAccountQuestion =>
      _t('ليس لديك حساب؟', "Don't have an account?");

  String get fullNameHint =>
      _t('الاسم الأول واسم العائلة', 'First and last name');

  String get phoneRequiredLabel => _t('رقم الهاتف', 'Phone number');

  String get phoneRequiredError =>
      _t('رقم الهاتف مطلوب', 'Phone number is required');

  String get phoneInvalidError =>
      _t('أدخل رقم هاتف صالحاً', 'Enter a valid phone number');

  String get birthDateHint =>
      _t('اختر تاريخ ميلادك', 'Select your date of birth');

  String get birthDateRequiredError =>
      _t('تاريخ الميلاد مطلوب', 'Date of birth is required');

  String get minimumAgeError => _t(
    'يجب أن يكون عمرك 18 سنة أو أكثر لإنشاء حساب',
    'You must be 18 or older to create an account',
  );

  String get forgotPasswordSubtitle => _t(
    'أدخل بريدك الإلكتروني وسنرسل لك رمز الاستعادة للوصول إلى حسابك.',
    "Enter your email and we'll send you a recovery code to get back into "
        'your account.',
  );

  String get sendRecoveryCode =>
      _t('إرسال رمز الاستعادة', 'Send recovery code');

  String resendIn(int seconds) =>
      _t('إعادة الإرسال بعد $seconds ث', 'Resend in ${seconds}s');

  String get resendCode => _t('إعادة إرسال الرمز', 'Resend code');

  String get sending => _t('جارٍ الإرسال...', 'Sending...');

  String get verifyCodeTitle => _t('تحقق من الرمز', 'Verify the code');

  String get verifyEmailTitle =>
      _t('تأكيد البريد الإلكتروني', 'Confirm your email');

  String get verifyCodeSubtitle => _t(
    'أدخل الرمز المكوّن من 6 أرقام الذي أرسلناه إلى بريدك.',
    "Enter the 6-digit code we sent to your email.",
  );

  String get verifyAction => _t('تحقق', 'Verify');

  String get confirmCodeAction => _t('تأكيد الرمز', 'Confirm code');

  String get newPasswordTitle => _t('كلمة مرور جديدة', 'New password');

  String get newPasswordSubtitle => _t(
    'اختر كلمة مرور قوية: 8 أحرف على الأقل، حرف كبير، ورقم.',
    'Choose a strong password: at least 8 characters, one uppercase letter '
        'and one number.',
  );

  String get newPasswordLabel => _t('كلمة المرور الجديدة', 'New password');

  String get changePasswordAction => _t('تغيير كلمة المرور', 'Change password');

  String get registerGreetingSubtitle => _t(
    'أنشئ حسابك وابدأ رحلتك التعليمية معنا',
    'Create your account and start learning with us',
  );

  String get allNotifications => _t('جميع الإشعارات', 'All notifications');

  String get customizeNotifications =>
      _t('تخصيص الإشعارات', 'Customize notifications');

  String enabledOf(int on, int total) => _t('$on من $total', '$on of $total');

  String get confirm => _t('تأكيد', 'Confirm');

  String ageYears(int years) => _t('العمر $years سنة', 'Age $years');

  String get backToSignIn => _t('العودة إلى تسجيل الدخول', 'Back to sign in');

  String get showPassword => _t('إظهار كلمة المرور', 'Show password');

  String get hidePassword => _t('إخفاء كلمة المرور', 'Hide password');

  String get dateLocale => isEnglish ? 'en' : 'ar';
}

class AppStringsScope extends InheritedWidget {
  const AppStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  final AppStrings strings;

  static AppStrings of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AppStringsScope>()
            ?.strings ??
        const AppStrings(appLocaleArabic);
  }

  @override
  bool updateShouldNotify(AppStringsScope oldWidget) {
    return strings.languageCode != oldWidget.strings.languageCode;
  }
}
