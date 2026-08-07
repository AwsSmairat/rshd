<?php

namespace App\Filament\Pages;

use App\Filament\Support\PlatformSettingsForms as PSF;
use App\Filament\Resources\AuditLogResource;
use App\Models\User;
use App\Services\PlatformAuditService;
use App\Services\PlatformBackupService;
use App\Services\PlatformSettingsService;
use App\Services\PlatformSystemStatusService;
use App\Support\AuditActionCatalog;
use Filament\Forms;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Contracts\Support\Htmlable;
use Illuminate\Support\Facades\Auth;
use Livewire\Attributes\Url;

class Settings extends Page implements HasForms
{
    use InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-cog-6-tooth';

    protected static ?string $navigationGroup = 'النظام';

    protected static ?string $navigationLabel = 'الإعدادات';

    protected static ?string $title = 'إعدادات المنصة';

    protected static ?int $navigationSort = 2;

    protected static string $view = 'filament.pages.settings';

    #[Url]
    public string $section = 'platform';

    /** @var array<string, mixed>|null */
    public ?array $platformData = [];

    /** @var array<string, mixed>|null */
    public ?array $emailData = [];

    /** @var array<string, mixed>|null */
    public ?array $socialData = [];

    /** @var array<string, mixed>|null */
    public ?array $paymentsData = [];

    /** @var array<string, mixed>|null */
    public ?array $registrationData = [];

    /** @var array<string, mixed>|null */
    public ?array $studentsData = [];

    /** @var array<string, mixed>|null */
    public ?array $instructorsData = [];

    /** @var array<string, mixed>|null */
    public ?array $notificationsData = [];

    /** @var array<string, mixed>|null */
    public ?array $securityData = [];

    /** @var array<string, mixed>|null */
    public ?array $backupData = [];

    /** @var array<string, mixed>|null */
    public ?array $auditData = [];

    /** @var array<string, mixed>|null */
    public ?array $maintenanceData = [];

    public static function canAccess(): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }

    public static function shouldRegisterNavigation(): bool
    {
        return static::canAccess();
    }

    public function getTitle(): string|Htmlable
    {
        return 'إعدادات المنصة';
    }

    public function getHeading(): string|Htmlable
    {
        return '';
    }

    public function mount(): void
    {
        if (! array_key_exists($this->section, $this->sections())) {
            $this->section = 'platform';
        }

        $settings = app(PlatformSettingsService::class);

        $this->platformForm->fill($settings->getGroup('platform'));
        $this->emailForm->fill($settings->getGroup('email'));
        $this->socialForm->fill(array_merge(
            $settings->getGroup('social'),
            ['support_phone' => $settings->get('support_phone', '', 'platform')],
        ));
        $this->paymentsForm->fill($settings->getGroup('payments'));
        $this->registrationForm->fill($settings->getGroup('registration'));
        $this->studentsForm->fill($settings->getGroup('students'));
        $this->instructorsForm->fill($settings->getGroup('instructors'));
        $this->notificationsForm->fill($settings->getGroup('notifications'));
        $this->securityForm->fill($settings->getGroup('security'));
        $this->backupForm->fill($settings->getGroup('backup'));
        $this->auditForm->fill($settings->getGroup('audit'));

        $platform = $settings->getGroup('platform');
        $this->maintenanceForm->fill([
            'maintenance_mode_enabled' => $platform['maintenance_mode_enabled'] ?? false,
            'maintenance_message' => $platform['maintenance_message'] ?? '',
        ]);
    }

    public function setSection(string $section): void
    {
        $sections = app(PlatformSettingsService::class)->sections();
        $this->section = array_key_exists($section, $sections) ? $section : 'platform';
    }

    public function sections(): array
    {
        return app(PlatformSettingsService::class)->sections();
    }

    public function sectionMeta(): array
    {
        return [
            'platform' => [
                'title' => 'معلومات المنصة',
                'subtitle' => 'المعلومات الأساسية التي تظهر في لوحة الإدارة والتطبيق',
                'save' => 'savePlatform',
                'button' => 'حفظ معلومات المنصة',
            ],
            'email' => [
                'title' => 'البريد الإلكتروني',
                'subtitle' => 'تفضيلات البريد العامة — بيانات SMTP في ملف البيئة',
                'save' => 'saveEmail',
                'button' => 'حفظ إعدادات البريد',
            ],
            'social' => [
                'title' => 'وسائل التواصل الاجتماعي',
                'subtitle' => 'روابط التواصل الظاهرة للطلاب والزوار',
                'save' => 'saveSocial',
                'button' => 'حفظ روابط التواصل',
            ],
            'payments' => [
                'title' => 'إعدادات الدفع النقدي',
                'subtitle' => 'سياسات التفعيل اليدوي والدفع النقدي',
                'save' => 'savePayments',
                'button' => 'حفظ إعدادات الدفع',
            ],
            'registration' => [
                'title' => 'إعدادات التسجيل',
                'subtitle' => 'سياسات إنشاء حسابات الطلاب والتحقق',
                'save' => 'saveRegistration',
                'button' => 'حفظ إعدادات التسجيل',
            ],
            'students' => [
                'title' => 'إعدادات الطلاب',
                'subtitle' => 'ربط الأجهزة والواجبات والاختبارات',
                'save' => 'saveStudents',
                'button' => 'حفظ إعدادات الطلاب',
            ],
            'instructors' => [
                'title' => 'إعدادات المدرسين',
                'subtitle' => 'صلاحيات المحتوى والمحاسبة للمدرسين',
                'save' => 'saveInstructors',
                'button' => 'حفظ إعدادات المدرسين',
            ],
            'notifications' => [
                'title' => 'الإشعارات',
                'subtitle' => 'تفضيلات الإشعارات داخل المنصة والبريد',
                'save' => 'saveNotifications',
                'button' => 'حفظ إعدادات الإشعارات',
            ],
            'security' => [
                'title' => 'الأمان',
                'subtitle' => 'سياسات الجلسات وكلمات المرور',
                'save' => 'saveSecurity',
                'button' => 'حفظ إعدادات الأمان',
            ],
            'backup' => [
                'title' => 'النسخ الاحتياطي',
                'subtitle' => 'إعدادات النسخ الاحتياطي — التنفيذ قيد التطوير',
                'save' => 'saveBackup',
                'button' => 'حفظ إعدادات النسخ',
            ],
            'audit' => [
                'title' => 'السجلات والنشاطات',
                'subtitle' => 'سياسات تسجيل النشاطات والاحتفاظ',
                'save' => 'saveAudit',
                'button' => 'حفظ إعدادات السجلات',
            ],
        ];
    }

    public function authUser(): ?User
    {
        /** @var User|null */
        return Auth::user();
    }

    public function adminInitials(): string
    {
        $name = trim((string) $this->authUser()?->name);
        if ($name === '') {
            return 'أ';
        }

        $parts = preg_split('/\s+/u', $name) ?: [];

        return mb_strtoupper(mb_substr($parts[0] ?? '', 0, 1).mb_substr($parts[1] ?? '', 0, 1));
    }

    public function systemStatus(): array
    {
        return app(PlatformSystemStatusService::class)->rows();
    }

    public function environmentStatus(): array
    {
        return app(PlatformSystemStatusService::class)->environment();
    }

    public function mailConfigured(): bool
    {
        return app(PlatformSystemStatusService::class)->mailConfigured();
    }

    public function platformForm(Form $form): Form
    {
        return $form->schema([
            Forms\Components\TextInput::make('platform_name')->label('اسم المنصة')->required()->maxLength(100),
            Forms\Components\TextInput::make('platform_subtitle')->label('الشعار الفرعي')->maxLength(150),
            Forms\Components\TextInput::make('support_email')->label('بريد الدعم')->email()->maxLength(150),
            Forms\Components\TextInput::make('support_phone')->label('هاتف الدعم')->tel()->maxLength(40),
            Forms\Components\TextInput::make('currency_code')->label('رمز العملة')->required()->maxLength(10),
            Forms\Components\TextInput::make('currency_symbol')->label('رمز عرض العملة')->required()->maxLength(20),
            Forms\Components\Textarea::make('activation_note')->label('ملاحظة التفعيل')->rows(3)->columnSpanFull(),
            Forms\Components\Textarea::make('platform_description')->label('وصف المنصة')->rows(3)->columnSpanFull(),
        ])->columns(2)->statePath('platformData');
    }

    public function emailForm(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Placeholder::make('smtp_notice')
                ->label('')
                ->content('بيانات SMTP الحساسة تتم إدارتها من ملف البيئة .env ولا يتم تخزينها هنا.')
                ->columnSpanFull(),
            Forms\Components\TextInput::make('public_contact_email')->label('البريد الإلكتروني العام')->email(),
            Forms\Components\TextInput::make('support_email')->label('البريد الإلكتروني للدعم')->email(),
            Forms\Components\TextInput::make('sender_display_name')->label('اسم المرسل')->maxLength(120),
            Forms\Components\TextInput::make('reply_to_email')->label('بريد الرد')->email(),
            PSF::toggle('otp_email_enabled', 'تفعيل رسائل تأكيد البريد'),
            PSF::toggle('instructor_invitation_email_enabled', 'تفعيل دعوات المدرسين'),
            PSF::toggle('password_reset_emails_enabled', 'تفعيل رسائل استعادة كلمة المرور'),
            Forms\Components\Placeholder::make('mail_status')
                ->label('خدمة البريد')
                ->content(fn (): string => $this->mailConfigured() ? 'متصل' : 'غير مهيأ')
                ->columnSpanFull(),
        ])->columns(2)->statePath('emailData');
    }

    public function socialForm(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Placeholder::make('social_notice')
                ->label('')
                ->content('تظهر هذه الروابط في صفحة «تواصل معنا» داخل تطبيق الطالب. الحقول الفارغة تظهر للطالب كـ «لم يضاف بعد». البريد من قسم البريد.')
                ->columnSpanFull(),
            Forms\Components\TextInput::make('support_phone')
                ->label('هاتف التواصل')
                ->tel()
                ->maxLength(40),
            PSF::url('website_url', 'رابط الموقع'),
            PSF::url('facebook_url', 'فيسبوك'),
            PSF::url('instagram_url', 'إنستغرام'),
            PSF::url('youtube_url', 'يوتيوب'),
            PSF::url('linkedin_url', 'لينكدإن'),
            Forms\Components\TextInput::make('whatsapp_number')->label('رقم واتساب')->tel()->maxLength(30),
        ])->columns(2)->statePath('socialData');
    }

    public function paymentsForm(Form $form): Form
    {
        return $form->schema([
            PSF::toggle('cash_payment_enabled', 'تفعيل الدفع النقدي'),
            Forms\Components\Select::make('default_activation_status')
                ->label('الحالة الافتراضية لطلب التفعيل')
                ->options(['pending' => 'قيد الانتظار', 'approved' => 'مفعّل'])
                ->required(),
            PSF::toggle('manual_activation_required', 'يتطلب تفعيل يدوي من الإدارة'),
            PSF::toggle('allow_instructor_view_sale_price', 'السماح للمدرس برؤية سعر البيع'),
            PSF::toggle('allow_instructor_activate_students', 'السماح للمدرس بتفعيل مادة لطالب'),
            Forms\Components\Textarea::make('payment_instructions')->label('تعليمات الدفع والتفعيل')->rows(3)->columnSpanFull(),
            Forms\Components\TextInput::make('default_currency')->label('العملة الافتراضية')->maxLength(10),
            PSF::toggle('auto_use_subject_price', 'استخدام سعر المادة تلقائياً عند التفعيل'),
        ])->columns(2)->statePath('paymentsData');
    }

    public function registrationForm(Form $form): Form
    {
        return $form->schema([
            PSF::toggle('student_self_registration_enabled', 'السماح للطلاب بإنشاء حساب'),
            PSF::toggle('email_verification_required', 'إلزام تأكيد البريد الإلكتروني'),
            Forms\Components\TextInput::make('otp_expiry_minutes')->label('مدة صلاحية رمز التحقق')->numeric()->minValue(1)->maxValue(60),
            Forms\Components\TextInput::make('otp_resend_cooldown_seconds')->label('مدة الانتظار قبل إعادة إرسال الرمز')->numeric()->minValue(15),
            Forms\Components\TextInput::make('max_otp_attempts')->label('الحد الأقصى لمحاولات الرمز')->numeric()->minValue(1)->maxValue(20),
            PSF::toggle('phone_required', 'رقم الهاتف مطلوب'),
            PSF::toggle('terms_required', 'إلزام الموافقة على الشروط'),
            Forms\Components\Select::make('default_account_status')
                ->label('الحالة الافتراضية للحساب الجديد')
                ->options(['active' => 'نشط', 'pending' => 'قيد المراجعة']),
        ])->columns(2)->statePath('registrationData');
    }

    public function studentsForm(Form $form): Form
    {
        return $form->schema([
            PSF::toggle('device_binding_enabled', 'تفعيل ربط الحساب بالجهاز'),
            PSF::toggle('device_id_required', 'إلزام إرسال معرف الجهاز'),
            Forms\Components\TextInput::make('max_active_devices')->label('الحد الأقصى للأجهزة النشطة')->numeric()->minValue(1)->maxValue(5),
            PSF::toggle('allow_assignment_resubmission', 'السماح بإعادة تسليم الواجب'),
            Forms\Components\TextInput::make('assignment_max_file_size_mb')->label('أقصى حجم لملف الواجب (MB)')->numeric()->minValue(1)->maxValue(100),
            Forms\Components\TagsInput::make('assignment_allowed_file_types')->label('أنواع ملفات الواجب المسموحة')->separator(','),
            PSF::toggle('allow_quiz_retake', 'السماح بإعادة الاختبار'),
            PSF::toggle('show_quiz_correct_answers', 'عرض الإجابات الصحيحة بعد الاختبار'),
            PSF::toggle('allow_pdf_annotations', 'تفعيل الملاحظات والرسم على PDF'),
            PSF::toggle('show_inactive_subjects', 'عرض المواد غير المفعلة'),
        ])->columns(2)->statePath('studentsData');
    }

    public function instructorsForm(Form $form): Form
    {
        return $form->schema([
            PSF::toggle('instructor_can_create_subjects', 'السماح للمدرس بإضافة مادة'),
            PSF::toggle('instructor_edit_own_only', 'المدرس يعدل مواده فقط'),
            PSF::toggle('instructor_can_upload_videos', 'السماح برفع الفيديوهات'),
            PSF::toggle('instructor_can_upload_files', 'السماح برفع ملفات الدروس'),
            PSF::toggle('instructor_can_create_assignments', 'السماح بإنشاء الواجبات'),
            PSF::toggle('instructor_can_create_quizzes', 'السماح بإنشاء الاختبارات'),
            PSF::toggle('instructor_can_grade_assignments', 'السماح بتصحيح الواجبات'),
            PSF::toggle('instructor_can_publish_announcements', 'السماح بنشر الإعلانات'),
            PSF::toggle('instructor_can_view_accounting', 'السماح بعرض محاسبة المنصة'),
            PSF::toggle('instructor_can_view_other_instructors', 'السماح بعرض بيانات المدرسين الآخرين'),
        ])->columns(2)->statePath('instructorsData');
    }

    public function notificationsForm(Form $form): Form
    {
        return $form->schema([
            PSF::toggle('in_app_notifications_enabled', 'تفعيل الإشعارات داخل التطبيق'),
            PSF::toggle('email_notifications_enabled', 'تفعيل إشعارات البريد'),
            PSF::toggle('push_notifications_enabled', 'تفعيل الإشعارات الفورية'),
            Forms\Components\Placeholder::make('push_note')
                ->label('')
                ->content('يتطلب تفعيل Firebase Cloud Messaging أو OneSignal لاحقاً.')
                ->visible(fn (): bool => ! ($this->notificationsData['push_notifications_enabled'] ?? false))
                ->columnSpanFull(),
            PSF::toggle('notify_student_subject_activated', 'إشعار الطالب عند تفعيل المادة'),
            PSF::toggle('notify_student_assignment_created', 'إشعار الطالب عند إنشاء واجب'),
            PSF::toggle('notify_student_quiz_created', 'إشعار الطالب عند إنشاء اختبار'),
            PSF::toggle('notify_student_grade_published', 'إشعار الطالب عند نشر الدرجة'),
            PSF::toggle('notify_student_announcement_published', 'إشعار الطالب عند نشر إعلان'),
            PSF::toggle('notify_instructor_assignment_submitted', 'إشعار المدرس عند تسليم واجب'),
            PSF::toggle('notify_admin_activation_request', 'إشعار الإدارة عند طلب تفعيل جديد'),
        ])->columns(2)->statePath('notificationsData');
    }

    public function securityForm(Form $form): Form
    {
        $registration = app(PlatformSettingsService::class)->getGroup('registration');
        $students = app(PlatformSettingsService::class)->getGroup('students');

        return $form->schema([
            Forms\Components\Placeholder::make('security_notice')
                ->label('')
                ->content('الأسرار تُخزَّن في ملف .env. يجب أن يكون APP_DEBUG=false في الإنتاج وتفعيل HTTPS.')
                ->columnSpanFull(),
            Forms\Components\Placeholder::make('email_verification_status')
                ->label('تأكيد البريد الإلكتروني')
                ->content(($registration['email_verification_required'] ?? true) ? 'مفعّل (من إعدادات التسجيل)' : 'غير مفعّل'),
            Forms\Components\Placeholder::make('device_binding_status')
                ->label('ربط الجهاز')
                ->content(($students['device_binding_enabled'] ?? true) ? 'مفعّل (من إعدادات الطلاب)' : 'غير مفعّل'),
            Forms\Components\TextInput::make('session_lifetime_minutes')->label('مدة الجلسة (دقيقة)')->numeric()->minValue(5),
            PSF::toggle('force_logout_after_password_change', 'تسجيل الخروج بعد تغيير كلمة المرور'),
            Forms\Components\TextInput::make('max_login_attempts')->label('الحد الأقصى لمحاولات الدخول')->numeric()->minValue(1),
            Forms\Components\TextInput::make('login_lockout_minutes')->label('مدة الحظر (دقيقة)')->numeric()->minValue(1),
            Forms\Components\TextInput::make('instructor_invitation_expiry_hours')->label('صلاحية دعوة المدرس (ساعة)')->numeric()->minValue(1),
            Forms\Components\TextInput::make('password_min_length')->label('الحد الأدنى لطول كلمة المرور')->numeric()->minValue(6),
            PSF::toggle('password_require_uppercase', 'إلزام حرف كبير'),
            PSF::toggle('password_require_number', 'إلزام رقم'),
            PSF::toggle('password_require_special', 'إلزام رمز خاص'),
        ])->columns(2)->statePath('securityData');
    }

    public function backupForm(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Placeholder::make('backup_todo')
                ->label('')
                ->content('يمكنك إنشاء نسخة احتياطية يدوياً أو جدولتها تلقائياً حسب الإعدادات أدناه.')
                ->columnSpanFull(),
            PSF::toggle('auto_backup_enabled', 'تفعيل النسخ الاحتياطي التلقائي'),
            Forms\Components\Select::make('backup_frequency')->label('تكرار النسخ')->options(['daily' => 'يومي', 'weekly' => 'أسبوعي']),
            Forms\Components\TextInput::make('retention_days')->label('مدة الاحتفاظ (يوم)')->numeric()->minValue(1),
            PSF::toggle('include_uploaded_files', 'تضمين الملفات المرفوعة'),
            PSF::toggle('include_database', 'تضمين قاعدة البيانات'),
            Forms\Components\TextInput::make('backup_notification_email')->label('بريد إشعار النسخ')->email(),
            Forms\Components\Placeholder::make('last_backup_at')->label('آخر نسخة')->content(fn () => $this->backupData['last_backup_at'] ?? '—'),
            Forms\Components\Placeholder::make('last_backup_status')->label('حالة آخر نسخة')->content(fn () => match ($this->backupData['last_backup_status'] ?? 'not_configured') {
                'success' => 'ناجحة',
                'failed' => 'فاشلة',
                default => 'غير مهيأ',
            }),
        ])->columns(2)->statePath('backupData');
    }

    public function auditForm(Form $form): Form
    {
        return $form->schema([
            PSF::toggle('audit_logging_enabled', 'تفعيل سجل النشاطات'),
            PSF::toggle('log_admin_actions', 'تسجيل إجراءات الإدارة'),
            PSF::toggle('log_instructor_actions', 'تسجيل إجراءات المدرسين'),
            PSF::toggle('log_activation_changes', 'تسجيل تغييرات التفعيل'),
            PSF::toggle('log_financial_changes', 'تسجيل التغييرات المالية'),
            PSF::toggle('log_device_resets', 'تسجيل إعادة تعيين الأجهزة'),
            PSF::toggle('log_auth_events', 'تسجيل أحداث المصادقة'),
            PSF::toggle('log_settings_changes', 'تسجيل تغييرات الإعدادات'),
            Forms\Components\TextInput::make('retention_days')->label('مدة الاحتفاظ (يوم)')->numeric()->minValue(7),
        ])->columns(2)->statePath('auditData');
    }

    public function maintenanceForm(Form $form): Form
    {
        return $form->schema([
            PSF::toggle('maintenance_mode_enabled', 'تفعيل وضع الصيانة'),
            Forms\Components\Textarea::make('maintenance_message')
                ->label('رسالة الصيانة')
                ->rows(3)
                ->default('الموقع حالياً تحت الصيانة، يرجى المحاولة لاحقاً.')
                ->columnSpanFull(),
            Forms\Components\Placeholder::make('maintenance_note')
                ->label('')
                ->content('وضع الصيانة على مستوى التطبيق — يبقى وصول المسؤول للوحة الإدارة متاحاً.')
                ->columnSpanFull(),
        ])->statePath('maintenanceData');
    }

    protected function getForms(): array
    {
        return [
            'platformForm',
            'emailForm',
            'socialForm',
            'paymentsForm',
            'registrationForm',
            'studentsForm',
            'instructorsForm',
            'notificationsForm',
            'securityForm',
            'backupForm',
            'auditForm',
            'maintenanceForm',
        ];
    }

    public function savePlatform(): void
    {
        $this->persistGroup('platform', $this->platformForm->getState(), exclude: [
            'maintenance_mode_enabled',
            'maintenance_message',
        ]);
    }

    public function saveEmail(): void
    {
        $this->persistGroup('email', $this->emailForm->getState());
    }

    public function saveSocial(): void
    {
        $state = $this->socialForm->getState();
        $phone = $state['support_phone'] ?? null;
        unset($state['support_phone']);

        $this->persistGroup('social', $state);

        if ($phone !== null) {
            app(PlatformSettingsService::class)->set('support_phone', $phone, 'platform');
        }
    }

    public function savePayments(): void
    {
        $this->persistGroup('payments', $this->paymentsForm->getState());
    }

    public function saveRegistration(): void
    {
        $this->persistGroup('registration', $this->registrationForm->getState());
    }

    public function saveStudents(): void
    {
        $this->persistGroup('students', $this->studentsForm->getState());
    }

    public function saveInstructors(): void
    {
        $this->persistGroup('instructors', $this->instructorsForm->getState());
    }

    public function saveNotifications(): void
    {
        $this->persistGroup('notifications', $this->notificationsForm->getState());
    }

    public function saveSecurity(): void
    {
        $this->persistGroup('security', $this->securityForm->getState());
    }

    public function saveBackup(): void
    {
        $this->persistGroup('backup', $this->backupForm->getState());
        $this->refreshBackupForm();
    }

    public function runBackupNow(): void
    {
        try {
            $result = app(PlatformBackupService::class)->runBackup();

            Notification::make()
                ->title('تم إنشاء النسخة الاحتياطية')
                ->body($result['filename'])
                ->success()
                ->send();
        } catch (\Throwable $exception) {
            Notification::make()
                ->title('فشل إنشاء النسخة الاحتياطية')
                ->body($exception->getMessage())
                ->danger()
                ->send();
        }

        $this->refreshBackupForm();
    }

    public function openAuditLogs(): void
    {
        $this->redirect(AuditLogResource::getUrl('index'));
    }

    protected function refreshBackupForm(): void
    {
        $this->backupData = app(PlatformSettingsService::class)->getGroup('backup');
        $this->backupForm->fill($this->backupData);
    }

    public function saveAudit(): void
    {
        $this->persistGroup('audit', $this->auditForm->getState());
    }

    public function saveMaintenance(): void
    {
        $data = $this->maintenanceForm->getState();
        app(PlatformSettingsService::class)->setGroup('platform', [
            'maintenance_mode_enabled' => $data['maintenance_mode_enabled'] ?? false,
            'maintenance_message' => $data['maintenance_message'] ?? '',
        ]);

        app(PlatformAuditService::class)->logSettings(
            'maintenance.updated',
            auth()->user(),
            ($data['maintenance_mode_enabled'] ?? false)
                ? 'تم تفعيل وضع الصيانة.'
                : 'تم تعطيل وضع الصيانة.',
        );

        $this->notifySaved();
    }

    /**
     * @param  array<string, mixed>  $data
     * @param  list<string>  $exclude
     */
    protected function persistGroup(string $group, array $data, array $exclude = []): void
    {
        foreach ($exclude as $key) {
            unset($data[$key]);
        }

        app(PlatformSettingsService::class)->setGroup($group, $data);

        app(PlatformAuditService::class)->logSettings(
            'settings.'.$group.'.updated',
            auth()->user(),
            'تم تحديث إعدادات '.AuditActionCatalog::settingsGroupLabel($group).'.',
        );

        $this->notifySaved();
    }

    protected function notifySaved(): void
    {
        Notification::make()
            ->title('تم حفظ الإعدادات بنجاح')
            ->success()
            ->send();
    }
}
