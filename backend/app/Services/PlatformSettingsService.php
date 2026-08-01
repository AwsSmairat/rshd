<?php

namespace App\Services;

use App\Models\PlatformSetting;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Storage;

class PlatformSettingsService
{
    public const CACHE_PREFIX = 'platform_setting.';

    public const CACHE_GROUP_PREFIX = 'platform_settings.group.';

    /**
     * @return array<string, array<string, array{type: string, value: mixed, is_public: bool}>>
     */
    public function definitions(): array
    {
        return [
            'platform' => [
                'platform_name' => ['type' => 'string', 'value' => 'RSHD', 'is_public' => true],
                'platform_subtitle' => ['type' => 'string', 'value' => 'منصة تعليمية ذكية', 'is_public' => true],
                'support_email' => ['type' => 'string', 'value' => 'admin@rshdacademy.com', 'is_public' => true],
                'support_phone' => ['type' => 'string', 'value' => '', 'is_public' => true],
                'currency_code' => ['type' => 'string', 'value' => 'JOD', 'is_public' => true],
                'currency_symbol' => ['type' => 'string', 'value' => 'د.أ', 'is_public' => true],
                'activation_note' => ['type' => 'string', 'value' => 'يتم تفعيل المواد يدوياً من الإدارة بعد الدفع النقدي.', 'is_public' => true],
                'platform_description' => ['type' => 'string', 'value' => '', 'is_public' => false],
                'maintenance_mode_enabled' => ['type' => 'boolean', 'value' => false, 'is_public' => false],
                'maintenance_message' => ['type' => 'string', 'value' => 'الموقع حالياً تحت الصيانة، يرجى المحاولة لاحقاً.', 'is_public' => false],
            ],
            'email' => [
                'public_contact_email' => ['type' => 'string', 'value' => 'admin@rshdacademy.com', 'is_public' => true],
                'support_email' => ['type' => 'string', 'value' => 'admin@rshdacademy.com', 'is_public' => true],
                'sender_display_name' => ['type' => 'string', 'value' => 'RSHD', 'is_public' => false],
                'reply_to_email' => ['type' => 'string', 'value' => 'admin@rshdacademy.com', 'is_public' => false],
                'otp_email_enabled' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'instructor_invitation_email_enabled' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'password_reset_emails_enabled' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
            ],
            'branding' => [
                'main_logo' => ['type' => 'string', 'value' => null, 'is_public' => true],
                'icon_logo' => ['type' => 'string', 'value' => null, 'is_public' => true],
                'favicon' => ['type' => 'string', 'value' => null, 'is_public' => true],
                'login_logo' => ['type' => 'string', 'value' => null, 'is_public' => true],
                'default_announcement_banner' => ['type' => 'string', 'value' => null, 'is_public' => false],
                'default_subject_image' => ['type' => 'string', 'value' => null, 'is_public' => false],
                'light_logo' => ['type' => 'string', 'value' => null, 'is_public' => true],
                'dark_logo' => ['type' => 'string', 'value' => null, 'is_public' => true],
                'color_primary_navy' => ['type' => 'string', 'value' => '#0B1F3A', 'is_public' => false],
                'color_gold_accent' => ['type' => 'string', 'value' => '#D6B56D', 'is_public' => false],
                'color_ivory_background' => ['type' => 'string', 'value' => '#F6F1E7', 'is_public' => false],
            ],
            'social' => [
                'website_url' => ['type' => 'string', 'value' => '', 'is_public' => true],
                'facebook_url' => ['type' => 'string', 'value' => '', 'is_public' => true],
                'instagram_url' => ['type' => 'string', 'value' => '', 'is_public' => true],
                'youtube_url' => ['type' => 'string', 'value' => '', 'is_public' => true],
                'linkedin_url' => ['type' => 'string', 'value' => '', 'is_public' => true],
                'whatsapp_number' => ['type' => 'string', 'value' => '', 'is_public' => true],
            ],
            'payments' => [
                'cash_payment_enabled' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'default_activation_status' => ['type' => 'string', 'value' => 'pending', 'is_public' => false],
                'manual_activation_required' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'allow_instructor_view_sale_price' => ['type' => 'boolean', 'value' => false, 'is_public' => false],
                'allow_instructor_activate_students' => ['type' => 'boolean', 'value' => false, 'is_public' => false],
                'payment_instructions' => ['type' => 'string', 'value' => 'يتم تفعيل المواد يدوياً من الإدارة بعد الدفع النقدي.', 'is_public' => true],
                'default_currency' => ['type' => 'string', 'value' => 'JOD', 'is_public' => true],
                'auto_use_subject_price' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
            ],
            'registration' => [
                'student_self_registration_enabled' => ['type' => 'boolean', 'value' => true, 'is_public' => true],
                'email_verification_required' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'otp_expiry_minutes' => ['type' => 'integer', 'value' => 10, 'is_public' => false],
                'otp_resend_cooldown_seconds' => ['type' => 'integer', 'value' => 60, 'is_public' => false],
                'max_otp_attempts' => ['type' => 'integer', 'value' => 5, 'is_public' => false],
                'phone_required' => ['type' => 'boolean', 'value' => false, 'is_public' => false],
                'terms_required' => ['type' => 'boolean', 'value' => false, 'is_public' => false],
                'default_account_status' => ['type' => 'string', 'value' => 'active', 'is_public' => false],
            ],
            'legal' => [
                'terms_current_version' => ['type' => 'string', 'value' => '1.0', 'is_public' => true],
                'terms_last_updated' => ['type' => 'string', 'value' => '2026/07/31', 'is_public' => true],
                'terms_requires_reacceptance' => ['type' => 'boolean', 'value' => false, 'is_public' => false],
            ],
            'students' => [
                'device_binding_enabled' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'device_id_required' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'max_active_devices' => ['type' => 'integer', 'value' => 1, 'is_public' => false],
                'allow_assignment_resubmission' => ['type' => 'boolean', 'value' => false, 'is_public' => false],
                'assignment_max_file_size_mb' => ['type' => 'integer', 'value' => 10, 'is_public' => true],
                'assignment_allowed_file_types' => ['type' => 'json', 'value' => ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'zip'], 'is_public' => true],
                'allow_quiz_retake' => ['type' => 'boolean', 'value' => false, 'is_public' => false],
                'show_quiz_correct_answers' => ['type' => 'boolean', 'value' => false, 'is_public' => false],
                'allow_pdf_annotations' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'show_inactive_subjects' => ['type' => 'boolean', 'value' => false, 'is_public' => false],
            ],
            'instructors' => [
                'instructor_can_create_subjects' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'instructor_edit_own_only' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'instructor_can_upload_videos' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'instructor_can_upload_files' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'instructor_can_create_assignments' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'instructor_can_create_quizzes' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'instructor_can_grade_assignments' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'instructor_can_publish_announcements' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'instructor_can_view_accounting' => ['type' => 'boolean', 'value' => false, 'is_public' => false],
                'instructor_can_view_other_instructors' => ['type' => 'boolean', 'value' => false, 'is_public' => false],
            ],
            'notifications' => [
                'in_app_notifications_enabled' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'email_notifications_enabled' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'push_notifications_enabled' => ['type' => 'boolean', 'value' => false, 'is_public' => false],
                'notify_student_subject_activated' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'notify_student_assignment_created' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'notify_student_quiz_created' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'notify_student_grade_published' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'notify_student_announcement_published' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'notify_instructor_assignment_submitted' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'notify_admin_activation_request' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
            ],
            'localization' => [
                'default_language' => ['type' => 'string', 'value' => 'ar', 'is_public' => true],
                'dashboard_direction' => ['type' => 'string', 'value' => 'rtl', 'is_public' => false],
                'timezone' => ['type' => 'string', 'value' => 'Asia/Amman', 'is_public' => false],
                'currency' => ['type' => 'string', 'value' => 'JOD', 'is_public' => true],
                'date_format' => ['type' => 'string', 'value' => 'Y-m-d', 'is_public' => false],
                'time_format' => ['type' => 'string', 'value' => '24', 'is_public' => false],
                'first_day_of_week' => ['type' => 'string', 'value' => 'saturday', 'is_public' => false],
                'number_format_locale' => ['type' => 'string', 'value' => 'ar-JO', 'is_public' => false],
            ],
            'security' => [
                'session_lifetime_minutes' => ['type' => 'integer', 'value' => 120, 'is_public' => false],
                'force_logout_after_password_change' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'max_login_attempts' => ['type' => 'integer', 'value' => 5, 'is_public' => false],
                'login_lockout_minutes' => ['type' => 'integer', 'value' => 15, 'is_public' => false],
                'instructor_invitation_expiry_hours' => ['type' => 'integer', 'value' => 72, 'is_public' => false],
                'password_min_length' => ['type' => 'integer', 'value' => 8, 'is_public' => false],
                'password_require_uppercase' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'password_require_number' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'password_require_special' => ['type' => 'boolean', 'value' => false, 'is_public' => false],
            ],
            'backup' => [
                'auto_backup_enabled' => ['type' => 'boolean', 'value' => false, 'is_public' => false],
                'backup_frequency' => ['type' => 'string', 'value' => 'daily', 'is_public' => false],
                'retention_days' => ['type' => 'integer', 'value' => 14, 'is_public' => false],
                'include_uploaded_files' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'include_database' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'backup_notification_email' => ['type' => 'string', 'value' => '', 'is_public' => false],
                'last_backup_at' => ['type' => 'string', 'value' => null, 'is_public' => false],
                'last_backup_status' => ['type' => 'string', 'value' => 'not_configured', 'is_public' => false],
            ],
            'audit' => [
                'audit_logging_enabled' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'log_admin_actions' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'log_instructor_actions' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'log_activation_changes' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'log_financial_changes' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'log_device_resets' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'log_auth_events' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'log_settings_changes' => ['type' => 'boolean', 'value' => true, 'is_public' => false],
                'retention_days' => ['type' => 'integer', 'value' => 90, 'is_public' => false],
            ],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function sections(): array
    {
        return [
            'platform' => 'معلومات المنصة',
            'email' => 'البريد الإلكتروني',
            'social' => 'وسائل التواصل الاجتماعي',
            'payments' => 'إعدادات الدفع النقدي',
            'registration' => 'إعدادات التسجيل',
            'students' => 'إعدادات الطلاب',
            'instructors' => 'إعدادات المدرسين',
            'notifications' => 'الإشعارات',
            'security' => 'الأمان',
            'backup' => 'النسخ الاحتياطي',
            'audit' => 'السجلات والنشاطات',
        ];
    }

    public function get(string $key, mixed $default = null, ?string $group = null): mixed
    {
        if ($group === null) {
            foreach ($this->definitions() as $groupName => $keys) {
                if (array_key_exists($key, $keys)) {
                    $group = $groupName;
                    break;
                }
            }
        }

        if ($group === null) {
            return $default;
        }

        $definition = $this->definitions()[$group][$key] ?? null;
        $defaultValue = $definition['value'] ?? $default;
        $type = $definition['type'] ?? 'string';

        $cacheKey = self::CACHE_PREFIX.$group.'.'.$key;

        $stored = Cache::rememberForever($cacheKey, function () use ($group, $key, $defaultValue) {
            $record = PlatformSetting::query()
                ->where('group', $group)
                ->where('key', $key)
                ->first();

            return $record?->value ?? $defaultValue;
        });

        return $this->castStoredValue($stored, $type, $defaultValue);
    }

    public function set(string $key, mixed $value, ?string $group = null): void
    {
        if ($group === null) {
            foreach ($this->definitions() as $groupName => $keys) {
                if (array_key_exists($key, $keys)) {
                    $group = $groupName;
                    break;
                }
            }
        }

        if ($group === null) {
            return;
        }

        $definition = $this->definitions()[$group][$key] ?? ['type' => 'string', 'is_public' => false];
        $encoded = $this->encodeValue($value, $definition['type']);

        PlatformSetting::query()->updateOrCreate(
            ['group' => $group, 'key' => $key],
            [
                'value' => $encoded,
                'type' => $definition['type'],
                'is_public' => $definition['is_public'] ?? false,
            ],
        );

        Cache::forget(self::CACHE_PREFIX.$group.'.'.$key);
        Cache::forget(self::CACHE_GROUP_PREFIX.$group);
        Cache::forget('platform_settings.public');
    }

    /**
     * @return array<string, mixed>
     */
    public function getGroup(string $group): array
    {
        return Cache::rememberForever(self::CACHE_GROUP_PREFIX.$group, function () use ($group) {
            $definitions = $this->definitions()[$group] ?? [];
            $stored = PlatformSetting::query()
                ->where('group', $group)
                ->get()
                ->keyBy('key');

            $values = [];
            foreach ($definitions as $key => $definition) {
                $raw = $stored->get($key)?->value ?? $definition['value'];
                $values[$key] = $this->castStoredValue($raw, $definition['type'], $definition['value']);
            }

            return $values;
        });
    }

    /**
     * @param  array<string, mixed>  $values
     */
    public function setGroup(string $group, array $values): void
    {
        foreach ($values as $key => $value) {
            $this->set($key, $value, $group);
        }
    }

    /**
     * @return array<string, mixed>
     */
    public function publicSettings(): array
    {
        return Cache::rememberForever('platform_settings.public', function () {
            $payload = [];

            foreach ($this->definitions() as $group => $keys) {
                foreach ($keys as $key => $definition) {
                    if (! ($definition['is_public'] ?? false)) {
                        continue;
                    }

                    $value = $this->get($key, $definition['value'], $group);

                    if (is_string($value) && $this->isBrandingKey($key) && filled($value)) {
                        $value = Storage::disk('public')->url($value);
                    }

                    $payload[$key] = $value;
                }
            }

            $payload['platform_subtitle'] = $payload['platform_subtitle'] ?? $this->get('platform_subtitle', null, 'platform');
            $payload['currency'] = $this->get('currency_code', 'JOD', 'platform');
            $payload['logo_url'] = filled($this->get('main_logo', null, 'branding'))
                ? Storage::disk('public')->url((string) $this->get('main_logo', null, 'branding'))
                : asset('images/rshd_logo_no_bg.png');

            return $payload;
        });
    }

    public function clearCache(): void
    {
        foreach ($this->definitions() as $group => $keys) {
            Cache::forget(self::CACHE_GROUP_PREFIX.$group);
            foreach (array_keys($keys) as $key) {
                Cache::forget(self::CACHE_PREFIX.$group.'.'.$key);
            }
        }

        Cache::forget('platform_settings.public');
    }

    public function isMaintenanceModeEnabled(): bool
    {
        return (bool) $this->get('maintenance_mode_enabled', false, 'platform');
    }

    public function maintenanceMessage(): string
    {
        $message = $this->get('maintenance_message', null, 'platform');

        return filled($message)
            ? (string) $message
            : 'الموقع حالياً تحت الصيانة، يرجى المحاولة لاحقاً.';
    }

    public function enabled(string $key, ?string $group = null): bool
    {
        return (bool) $this->get($key, false, $group);
    }

    public function integer(string $key, int $default = 0, ?string $group = null): int
    {
        return (int) $this->get($key, $default, $group);
    }

    public function stringValue(string $key, string $default = '', ?string $group = null): string
    {
        $value = $this->get($key, $default, $group);

        return is_string($value) ? $value : (string) ($value ?? $default);
    }

    /**
     * @return array<int, mixed>
     */
    public function arrayValue(string $key, array $default = [], ?string $group = null): array
    {
        $value = $this->get($key, $default, $group);

        return is_array($value) ? $value : $default;
    }

    public function platformName(): string
    {
        return $this->stringValue('platform_name', 'RSHD', 'platform');
    }

    public function platformSubtitle(): string
    {
        return $this->stringValue('platform_subtitle', 'منصة تعليمية ذكية', 'platform');
    }

    public function emailVerificationRequired(): bool
    {
        return $this->enabled('email_verification_required', 'registration');
    }

    public function studentRegistrationEnabled(): bool
    {
        return $this->enabled('student_self_registration_enabled', 'registration');
    }

    public function deviceBindingEnabled(): bool
    {
        return $this->enabled('device_binding_enabled', 'students');
    }

    public function deviceIdRequired(): bool
    {
        return $this->enabled('device_id_required', 'students');
    }

    public function applyMailPreferences(): void
    {
        $fromName = $this->stringValue('sender_display_name', '', 'email');
        if ($fromName !== '') {
            config(['mail.from.name' => $fromName]);
        }

        $replyTo = $this->stringValue('reply_to_email', '', 'email');
        if ($replyTo !== '') {
            config([
                'mail.reply_to' => [
                    'address' => $replyTo,
                    'name' => $fromName !== '' ? $fromName : config('mail.from.name'),
                ],
            ]);
        }
    }

    public function applySecurityPreferences(): void
    {
        $minutes = max(5, $this->integer('session_lifetime_minutes', 120, 'security'));

        config([
            'session.lifetime' => $minutes,
            'sanctum.expiration' => $minutes,
        ]);
    }

    public function passwordResetEmailsEnabled(): bool
    {
        return $this->enabled('password_reset_emails_enabled', 'email');
    }

    /**
     * @return list<string|\Illuminate\Contracts\Validation\ValidationRule>
     */
    public function passwordRules(bool $confirmed = false): array
    {
        $rules = ['required', 'string', 'min:'.$this->integer('password_min_length', 8, 'security')];

        if ($this->enabled('password_require_uppercase', 'security')) {
            $rules[] = 'regex:/[A-Z]/u';
        }

        if ($this->enabled('password_require_number', 'security')) {
            $rules[] = 'regex:/[0-9]/';
        }

        if ($this->enabled('password_require_special', 'security')) {
            $rules[] = 'regex:/[^A-Za-z0-9]/u';
        }

        if ($confirmed) {
            $rules[] = 'confirmed';
        }

        return $rules;
    }

    /**
     * @return list<string>
     */
    public function assignmentFileRules(): array
    {
        $maxMb = max(1, $this->integer('assignment_max_file_size_mb', 10, 'students'));
        $types = $this->arrayValue(
            'assignment_allowed_file_types',
            ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'zip'],
            'students',
        );
        $mimes = implode(',', array_map(
            static fn ($type) => ltrim(strtolower((string) $type), '.'),
            $types,
        ));

        return [
            'nullable',
            'file',
            'max:'.($maxMb * 1024),
            'mimes:'.$mimes,
        ];
    }

    /**
     * @return list<string>
     */
    public function deviceIdRules(): array
    {
        if (! $this->deviceBindingEnabled()) {
            return ['nullable', 'string', 'max:255'];
        }

        if ($this->deviceIdRequired()) {
            return ['required', 'string', 'max:255'];
        }

        return ['nullable', 'string', 'max:255'];
    }

    public function logoUrl(): ?string
    {
        $path = $this->get('main_logo', null, 'branding');

        return filled($path)
            ? \Illuminate\Support\Facades\Storage::disk('public')->url((string) $path)
            : null;
    }

    public function faviconUrl(): string
    {
        foreach (['favicon', 'icon_logo'] as $key) {
            $path = $this->get($key, null, 'branding');

            if (filled($path)) {
                return \Illuminate\Support\Facades\Storage::disk('public')->url((string) $path);
            }
        }

        return asset('images/favicon-32.png');
    }

    public function iconLogoUrl(): string
    {
        $path = $this->get('icon_logo', null, 'branding');

        if (filled($path)) {
            return \Illuminate\Support\Facades\Storage::disk('public')->url((string) $path);
        }

        return $this->faviconUrl();
    }

    protected function isBrandingKey(string $key): bool
    {
        return in_array($key, [
            'main_logo',
            'icon_logo',
            'favicon',
            'login_logo',
            'default_announcement_banner',
            'default_subject_image',
            'light_logo',
            'dark_logo',
        ], true);
    }

    protected function castStoredValue(mixed $stored, string $type, mixed $default): mixed
    {
        if ($stored === null) {
            return $default;
        }

        return match ($type) {
            'boolean' => filter_var($stored, FILTER_VALIDATE_BOOLEAN),
            'integer' => (int) $stored,
            'json' => is_array($stored)
                ? $stored
                : (json_decode((string) $stored, true) ?? $default),
            default => $stored,
        };
    }

    protected function encodeValue(mixed $value, string $type): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        return match ($type) {
            'boolean' => $value ? '1' : '0',
            'integer' => (string) (int) $value,
            'json' => json_encode($value, JSON_UNESCAPED_UNICODE),
            default => (string) $value,
        };
    }
}
