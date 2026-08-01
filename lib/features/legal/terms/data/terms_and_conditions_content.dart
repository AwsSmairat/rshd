import 'package:flutter/material.dart';

import 'terms_and_conditions_config.dart';
import 'terms_and_conditions_model.dart';

class TermsAndConditionsContent {
  TermsAndConditionsContent._();

  static TermsDocument buildLocalDocument({
    bool requiresAcceptance = false,
    String? acceptedVersion,
  }) {
    return TermsDocument(
      title: 'الشروط والأحكام',
      subtitle: 'يرجى قراءة شروط استخدام منصة RSHD بعناية',
      version: TermsAndConditionsConfig.termsVersion,
      lastUpdated: TermsAndConditionsConfig.termsLastUpdated,
      source: TermsSource.local,
      requiresAcceptance: requiresAcceptance,
      acceptedVersion: acceptedVersion,
      sections: sections,
    );
  }

  static final List<TermsSectionData> sections = [
    TermsSectionData(
      id: 'intro',
      title: 'مقدمة وقبول الشروط',
      icon: Icons.handshake_outlined,
      paragraphs: [
        'تنظم هذه الشروط استخدام تطبيق ومنصة RSHD والخدمات التعليمية المرتبطة بها. '
            'باستخدام المنصة أو إنشاء حساب فيها، يقر المستخدم بأنه قرأ هذه الشروط وفهمها ووافق على الالتزام بها.',
        'إذا كنت لا توافق على هذه الشروط، يرجى عدم استخدام المنصة أو إنشاء حساب.',
      ],
    ),
    TermsSectionData(
      id: 'definitions',
      title: 'تعريفات أساسية',
      icon: Icons.menu_book_outlined,
      subsections: [
        TermsSubsection(title: 'المنصة', items: ['نظام RSHD التعليمي ولوحة الإدارة والخدمات المرتبطة به.']),
        TermsSubsection(title: 'التطبيق', items: ['تطبيق الطالب أو أي تطبيق رسمي تابع للمنصة.']),
        TermsSubsection(title: 'المستخدم', items: ['أي شخص ينشئ حسابًا أو يستخدم الخدمة.']),
        TermsSubsection(title: 'الطالب', items: ['مستخدم مسجل للتعلم والوصول إلى المواد.']),
        TermsSubsection(title: 'المدرس', items: ['مستخدم مخول برفع المحتوى وإدارة الطلاب ضمن صلاحياته.']),
        TermsSubsection(title: 'الحساب', items: ['هوية المستخدم الإلكترونية وبيانات الدخول.']),
        TermsSubsection(title: 'المحتوى التعليمي', items: ['الدروس والفيديوهات والملفات والواجبات والاختبارات.']),
        TermsSubsection(title: 'الاشتراك', items: ['الوصول المفعّل لمادة أو خدمة مدفوعة أو معتمدة.']),
        TermsSubsection(title: 'الخدمات الخارجية', items: ['Google Sign-In وApple Sign-In وخدمات الاستضافة والبريد.']),
      ],
    ),
    TermsSectionData(
      id: 'eligibility',
      title: 'أهلية استخدام المنصة',
      icon: Icons.verified_user_outlined,
      bulletPoints: [
        'يجب تقديم معلومات صحيحة وحديثة.',
        'يجب امتلاك الأهلية القانونية المناسبة لاستخدام الخدمة.',
        'قد يحتاج القاصر إلى موافقة ولي الأمر أو المؤسسة التعليمية.',
        'قد يُنشأ الحساب بواسطة مؤسسة تعليمية أو الإدارة.',
        'لا يجوز استخدام حساب شخص آخر.',
      ],
    ),
    TermsSectionData(
      id: 'account_creation',
      title: 'إنشاء الحساب',
      icon: Icons.person_add_outlined,
      bulletPoints: [
        'تقديم معلومات دقيقة ومحدّثة.',
        'المحافظة على سرية كلمة المرور.',
        'عدم مشاركة الحساب أو رمز التحقق.',
        'إبلاغ المنصة عند الاشتباه بالدخول غير المصرح به.',
        'تحمل مسؤولية النشاط من خلال الحساب ضمن ما يسمح به القانون.',
      ],
      paragraphs: [
        'يمكنك إدارة الأمان والجلسات من صفحة الإعدادات → الأمان وكلمة المرور.',
      ],
    ),
    TermsSectionData(
      id: 'devices',
      title: 'استخدام الحساب والأجهزة',
      icon: Icons.devices_outlined,
      paragraphs: [
        'قد يسمح النظام بربط عدد محدود من الأجهزة للحساب الواحد. '
            'الحد الحالي المعتمد في هذه النسخة: ${TermsAndConditionsConfig.maximumAllowedDevices} جهاز(أجهزة) نشط(ة) — '
            'وقد يختلف حسب إعدادات المنصة.',
      ],
      bulletPoints: [
        'الحساب شخصي ولا يجوز بيعه أو تأجيره.',
        'يجوز إنهاء الجلسات القديمة عند تسجيل جهاز جديد.',
        'لا يجوز تجاوز قيود الأجهزة بطرق غير مشروعة.',
        'يحق للمنصة طلب إعادة تسجيل الدخول عند نشاط مشبوه.',
      ],
    ),
    TermsSectionData(
      id: 'educational_services',
      title: 'الخدمات التعليمية',
      icon: Icons.school_outlined,
      paragraphs: ['قد توفر المنصة:', 'قد يختلف توفر المحتوى حسب الاشتراك والمؤسسة والمادة والمدرس ونوع الحساب.'],
      bulletPoints: [
        'مواد ودورات تعليمية.',
        'فيديوهات وملفات PDF.',
        'واجبات واختبارات.',
        'درجات وتقارير.',
        'إعلانات وإشعارات داخل التطبيق.',
      ],
    ),
    TermsSectionData(
      id: 'student_obligations',
      title: 'التزامات الطالب',
      icon: Icons.person_outline,
      bulletPoints: [
        'استخدام المنصة للأغراض التعليمية.',
        'تقديم الواجبات بنفسه دون غش.',
        'عدم انتحال شخصية آخر.',
        'عدم مشاركة أسئلة أو إجابات الاختبار دون إذن.',
        'احترام المدرسين والطلاب.',
        'عدم إساءة استخدام الرسائل أو التعليقات.',
        'عدم محاولة الوصول إلى مواد غير مشترك بها.',
        'الالتزام بمواعيد الواجبات والاختبارات.',
      ],
    ),
    TermsSectionData(
      id: 'instructor_obligations',
      title: 'التزامات المدرس',
      icon: Icons.co_present_outlined,
      bulletPoints: [
        'رفع محتوى يملك حق استخدامه.',
        'عدم نشر بيانات شخصية للطلاب دون مبرر.',
        'تقييم الطلاب بصورة عادلة.',
        'عدم مشاركة بيانات الدخول.',
        'عدم استخدام المنصة لنشر محتوى مسيء أو مخالف.',
        'الالتزام بالسياسات التعليمية المعتمدة.',
        'المحافظة على سرية الدرجات والتسليمات.',
      ],
    ),
    TermsSectionData(
      id: 'acceptable_use',
      title: 'قواعد السلوك والاستخدام المقبول',
      icon: Icons.block_outlined,
      bulletPoints: [
        'اختراق المنصة أو محاولة تجاوز الحماية.',
        'اختبار الثغرات دون تصريح كتابي.',
        'إدخال برمجيات ضارة أو تعطيل الخوادم.',
        'انتحال شخصية أو إنشاء حسابات وهمية.',
        'إرسال رسائل مزعجة أو التحرش أو التهديد.',
        'نشر محتوى غير قانوني أو مسيء.',
        'سرقة المحتوى أو مشاركة الحساب.',
        'تجاوز وسائل حماية الفيديو والملفات.',
        'استخدام أدوات آلية لجمع البيانات دون إذن.',
      ],
    ),
    TermsSectionData(
      id: 'academic_integrity',
      title: 'الاختبارات والغش الأكاديمي',
      icon: Icons.fact_check_outlined,
      bulletPoints: [
        'يمنع استخدام حساب طالب آخر.',
        'يمنع تصوير أو نسخ أسئلة الاختبار دون إذن.',
        'يمنع مشاركة الإجابات.',
        'قد يُسجَّل وقت الدخول والنشاط داخل الاختبار.',
        'قد تُلغى المحاولة أو تُحال للمراجعة عند نشاط مشبوه.',
        'للطالب تقديم اعتراض وفق الإجراءات المتاحة.',
      ],
      paragraphs: [
        'لا تضمن المنصة دقة مطلقة في أنظمة كشف الغش؛ تُستخدم كأداة مساعدة للمراجعة.',
      ],
    ),
    TermsSectionData(
      id: 'subscriptions',
      title: 'الاشتراكات والمدفوعات',
      icon: Icons.payments_outlined,
      paragraphs: [
        'تُدار التفعيلات حاليًا يدويًا بعد الدفع النقدي وفق تعليمات المنصة. '
            'لا يوجد تجديد تلقائي للاشتراك داخل التطبيق حاليًا.',
      ],
      bulletPoints: [
        'يظهر سعر المادة أو التفعيل قبل الطلب عند توفره.',
        'قد تُطبَّق العملة والضرائب حسب السياسة المعتمدة.',
        'مدة الوصول تبدأ من تاريخ التفعيل المعتمد.',
        'لا تُخزَّن بيانات البطاقة الكاملة داخل المنصة عند استخدام بوابة خارجية مستقبلًا.',
      ],
    ),
    TermsSectionData(
      id: 'refunds',
      title: 'الإلغاء والاسترداد',
      icon: Icons.receipt_long_outlined,
      paragraphs: [
        'مدة تقديم طلب الاسترداد: ${TermsAndConditionsConfig.refundRequestPeriod}.',
        'مدة معالجة الطلب: ${TermsAndConditionsConfig.refundProcessingPeriod}.',
      ],
      bulletPoints: [
        'يُقدَّم الطلب عبر قنوات الدعم المعتمدة.',
        'قد تُستثنى حالات بدء مشاهدة المحتوى أو استخدامه.',
        'قرار الاسترداد يخضع للسياسة المعتمدة وطريقة الدفع.',
      ],
    ),
    TermsSectionData(
      id: 'intellectual_property',
      title: 'الملكية الفكرية',
      icon: Icons.copyright_outlined,
      bulletPoints: [
        'تصميم المنصة وبرمجتها وشعارها محمية.',
        'حقوق المحتوى قد تعود إلى RSHD أو المدرس أو الجهة المرخصة.',
        'الاشتراك يمنح حق استخدام شخصي محدود وليس ملكية.',
        'يمنع إعادة النشر أو البيع أو النسخ أو التوزيع دون إذن.',
        'يمنع إزالة العلامات المائية أو وسائل الحماية.',
        'عرض الملفات داخل التطبيق فقط؛ لا يُوفَّر تنزيل عام حاليًا.',
      ],
    ),
    TermsSectionData(
      id: 'user_content',
      title: 'المحتوى الذي يرفعه المستخدم',
      icon: Icons.upload_file_outlined,
      bulletPoints: [
        'يجب امتلاك حق رفع الملف أو الصورة أو النص.',
        'لا يجوز رفع محتوى مخالف أو مسيء.',
        'يمنح المستخدم المنصة إذنًا تقنيًا لتخزين المحتوى وعرضه ضمن الخدمة.',
        'يبقى المستخدم مسؤولًا عن محتواه.',
        'يمكن إزالة المحتوى المخالف بعد المراجعة.',
      ],
    ),
    TermsSectionData(
      id: 'messaging',
      title: 'الرسائل والتواصل',
      icon: Icons.chat_outlined,
      bulletPoints: [
        'استخدام الرسائل لأغراض تعليمية.',
        'منع الإزعاج والتهديد والتحرش.',
        'إمكانية الإبلاغ عن المحادثة.',
        'مراجعة البلاغات من أشخاص مخولين.',
        'عدم إرسال كلمات المرور أو بيانات الدفع عبر الرسائل.',
      ],
    ),
    TermsSectionData(
      id: 'notifications',
      title: 'الإعلانات والإشعارات',
      icon: Icons.notifications_outlined,
      bulletPoints: [
        'تنبيهات الدروس والواجبات والاختبارات.',
        'إشعارات الدرجات والرسائل.',
        'الإعلانات الإدارية وتحديثات الخدمة.',
        'يمكن التحكم في الإشعارات الاختيارية من الإعدادات.',
        'قد تبقى بعض إشعارات الأمان والخدمة ضرورية.',
      ],
    ),
    TermsSectionData(
      id: 'external_services',
      title: 'الخدمات والروابط الخارجية',
      icon: Icons.open_in_new_outlined,
      paragraphs: [
        'قد تستخدم المنصة خدمات خارجية مثل:',
        'تخضع هذه الخدمات لشروط وسياسات مستقلة.',
      ],
      bulletPoints: [
        'Google Sign-In وSign in with Apple.',
        'خادم المنصة (Laravel API).',
        'مزود البريد الإلكتروني.',
        'مشغّل الفيديو وعارض PDF داخل التطبيق.',
      ],
    ),
    TermsSectionData(
      id: 'availability',
      title: 'توفر الخدمة والصيانة',
      icon: Icons.build_circle_outlined,
      bulletPoints: [
        'تسعى المنصة لتوفير الخدمة بصورة مستقرة.',
        'قد تحدث صيانة أو انقطاعات مؤقتة.',
        'قد يتأثر الأداء بالإنترنت أو مزودي الخدمات.',
        'يمكن إضافة أو تعديل أو إزالة بعض الميزات.',
        'يُشعَر المستخدم بالتغييرات المهمة عند الإمكان.',
      ],
    ),
    TermsSectionData(
      id: 'grades_accuracy',
      title: 'الدقة التعليمية والدرجات',
      icon: Icons.grade_outlined,
      bulletPoints: [
        'المدرس أو المؤسسة مسؤولان عن اعتماد بعض الدرجات.',
        'النتائج قد تخضع للمراجعة.',
        'يجب الإبلاغ عن الأخطاء التقنية.',
        'المنصة ليست بديلًا عن تعليمات المؤسسة الرسمية.',
        'الشهادات ليست اعتمادًا رسميًا إلا إذا ذُكر ذلك صراحة.',
      ],
    ),
    TermsSectionData(
      id: 'suspension',
      title: 'إيقاف الحساب وتعليقه',
      icon: Icons.pause_circle_outline,
      bulletPoints: [
        'مخالفة الشروط أو الغش أو مشاركة الحساب.',
        'محاولات الاختراق أو إساءة الرسائل.',
        'عدم سداد المستحقات أو طلب جهة مخولة.',
        'نشاط يهدد أمن المنصة.',
        'إمكانية التعليق المؤقت أو طلب معلومات إضافية.',
        'إمكانية الاعتراض عبر الدعم.',
      ],
    ),
    TermsSectionData(
      id: 'user_termination',
      title: 'إنهاء الحساب بواسطة المستخدم',
      icon: Icons.logout_outlined,
      bulletPoints: [
        'يمكن طلب إغلاق الحساب من الإعدادات أو صفحة حذف الحساب.',
        'يؤدي الإغلاق إلى فقدان الوصول للمواد.',
        'قد تُحفظ سجلات لأسباب قانونية أو مالية.',
        'يجب تسوية المبالغ المستحقة قبل الإغلاق إن وجدت.',
      ],
      paragraphs: ['راجع قسم «حذف الحساب» في نهاية الصفحة.'],
    ),
    TermsSectionData(
      id: 'privacy_link',
      title: 'الخصوصية وحماية البيانات',
      icon: Icons.shield_outlined,
      paragraphs: [
        'تتم معالجة بيانات المستخدم وفق سياسة الخصوصية الخاصة بمنصة RSHD.',
        'استخدم زر «سياسة الخصوصية» في نهاية الصفحة لقراءة التفاصيل.',
      ],
    ),
    TermsSectionData(
      id: 'liability',
      title: 'حدود المسؤولية',
      icon: Icons.balance_outlined,
      bulletPoints: [
        'تتخذ المنصة إجراءات معقولة لتقديم الخدمة وحمايتها.',
        'قد تقع أعطال أو انقطاعات خارجة عن السيطرة.',
        'لا تتحمل المنصة مسؤولية سوء استخدام المستخدم لحسابه.',
        'لا تتحمل مسؤولية المحتوى الخارجي الذي لا تديره.',
        'لا تُستبعد مسؤولية لا يجوز استبعادها قانونيًا.',
      ],
    ),
    TermsSectionData(
      id: 'indemnity',
      title: 'التعويض عن الأضرار',
      icon: Icons.gavel_outlined,
      paragraphs: [
        'قد يتحمل المستخدم نتائج الأضرار الناتجة عن استخدام غير قانوني، '
            'أو انتهاك حقوق الآخرين، أو رفع محتوى لا يملك حقوقه، '
            'أو محاولة اختراق المنصة، أو مخالفة جوهرية للشروط — '
            'وفق ما يسمح به القانون المعمول به.',
      ],
    ),
    TermsSectionData(
      id: 'force_majeure',
      title: 'القوة القاهرة',
      icon: Icons.cloud_off_outlined,
      bulletPoints: [
        'الكوارث الطبيعية.',
        'انقطاع الإنترنت أو الكهرباء الواسع.',
        'القرارات الحكومية.',
        'هجمات إلكترونية كبيرة.',
        'تعطل مزودي الخدمات الخارجيين.',
      ],
    ),
    TermsSectionData(
      id: 'governing_law',
      title: 'القانون والاختصاص',
      icon: Icons.account_balance_outlined,
      paragraphs: [
        'تخضع هذه الشروط لـ${TermsAndConditionsConfig.governingLaw}. '
            'تُعالَج النزاعات وفق ${TermsAndConditionsConfig.disputeJurisdiction}.',
        if (TermsAndConditionsConfig.companyCountry.isNotEmpty)
          'الدولة المعتمدة: ${TermsAndConditionsConfig.companyCountry}.',
      ],
    ),
    TermsSectionData(
      id: 'disputes',
      title: 'الشكاوى وتسوية النزاعات',
      icon: Icons.support_agent_outlined,
      bulletPoints: [
        'التواصل أولًا مع الدعم.',
        'إرسال تفاصيل المشكلة عبر البريد المعتمد.',
        'منح المنصة مدة مناسبة للرد.',
        'التصعيد وفق الإجراءات المعتمدة.',
      ],
    ),
    TermsSectionData(
      id: 'updates',
      title: 'تحديث الشروط',
      icon: Icons.update_outlined,
      paragraphs: [
        'قد يتم تحديث هذه الشروط عند إضافة خدمات جديدة أو تعديل آلية الاستخدام. '
            'سيتم تغيير تاريخ آخر تحديث، وقد يُطلب من المستخدم الموافقة على النسخة الجديدة '
            'عند وجود تغييرات جوهرية.',
      ],
    ),
    TermsSectionData(
      id: 'contact',
      title: 'التواصل معنا',
      icon: Icons.mail_outline,
      paragraphs: ['للاستفسارات أو الإبلاغ عن مخالفة، راجع بطاقة التواصل في أسفل الصفحة.'],
    ),
  ];
}
