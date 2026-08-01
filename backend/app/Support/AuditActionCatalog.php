<?php

namespace App\Support;

use App\Models\AuditLog;

class AuditActionCatalog
{
    /**
     * @var array<string, string>
     */
    private const ACTION_LABELS = [
        'student.created' => 'إنشاء طالب',
        'student.updated' => 'تحديث طالب',
        'student.deleted' => 'حذف طالب',
        'admin.created' => 'إنشاء مسؤول',
        'admin.updated' => 'تحديث مسؤول',
        'admin.deleted' => 'حذف مسؤول',
        'instructor.created' => 'إنشاء مدرس',
        'instructor.updated' => 'تحديث مدرس',
        'instructor.deleted' => 'حذف مدرس',
        'instructor.invitation_resent' => 'إعادة دعوة مدرس',
        'notification.created' => 'إرسال إشعار',
        'notification.updated' => 'تحديث إشعار',
        'notification.deleted' => 'حذف إشعار',
        'announcement.created' => 'إنشاء إعلان',
        'announcement.updated' => 'تحديث إعلان',
        'announcement.deleted' => 'حذف إعلان',
        'expense.created' => 'إنشاء مصروف',
        'expense.updated' => 'تحديث مصروف',
        'expense.deleted' => 'حذف مصروف',
        'settings.group.updated' => 'تحديث إعدادات',
        'maintenance.updated' => 'وضع الصيانة',
        'enrollment.requested' => 'طلب تفعيل',
        'enrollment.activated' => 'تفعيل مادة',
        'enrollment.revoked' => 'إلغاء تفعيل',
        'register.created' => 'تسجيل طالب',
        'login.success' => 'دخول ناجح',
        'login.failed' => 'محاولة دخول فاشلة',
        'logout' => 'تسجيل خروج',
        'instructor.password_set' => 'تعيين كلمة مرور',
        'device.reset' => 'إعادة تعيين أجهزة',
    ];

    /**
     * @var array<string, string>
     */
    private const SETTINGS_GROUP_LABELS = [
        'platform' => 'المنصة',
        'email' => 'البريد',
        'social' => 'التواصل',
        'payments' => 'المدفوعات',
        'registration' => 'التسجيل',
        'students' => 'الطلاب',
        'instructors' => 'المدرسين',
        'notifications' => 'الإشعارات',
        'security' => 'الأمان',
        'backup' => 'النسخ الاحتياطي',
        'audit' => 'سجل النشاطات',
    ];

    /**
     * @var array<string, string>
     */
    private const MODEL_LABELS = [
        'User' => 'مستخدم',
        'Announcement' => 'إعلان',
        'Expense' => 'مصروف',
        'SubjectStudent' => 'تسجيل مادة',
        'Notification' => 'إشعار',
    ];

    /**
     * @var array<string, string>
     */
    private const CATEGORY_LABELS = [
        'users' => 'المستخدمون',
        'content' => 'المحتوى والإشعارات',
        'settings' => 'الإعدادات',
        'activation' => 'التفعيل',
        'financial' => 'المالية',
        'auth' => 'المصادقة',
        'devices' => 'الأجهزة',
    ];

    public static function actionLabel(string $action): string
    {
        if (isset(self::ACTION_LABELS[$action])) {
            return self::ACTION_LABELS[$action];
        }

        if (preg_match('/^settings\.([a-z_]+)\.updated$/', $action, $matches)) {
            return 'تحديث إعدادات '.self::settingsGroupLabel($matches[1]);
        }

        return $action;
    }

    public static function actionColor(string $action): string
    {
        if (str_starts_with($action, 'settings.') || $action === 'maintenance.updated') {
            return 'warning';
        }

        if (str_starts_with($action, 'enrollment.')) {
            return 'success';
        }

        if (str_starts_with($action, 'expense.')) {
            return 'danger';
        }

        if (in_array($action, ['login.failed'], true)) {
            return 'danger';
        }

        if (str_starts_with($action, 'login.') || str_starts_with($action, 'logout') || str_starts_with($action, 'register.')) {
            return 'gray';
        }

        if (str_starts_with($action, 'device.')) {
            return 'info';
        }

        return 'primary';
    }

    public static function category(string $action): string
    {
        if (str_starts_with($action, 'settings.') || $action === 'maintenance.updated' || $action === 'settings.group.updated') {
            return 'settings';
        }

        if (str_starts_with($action, 'enrollment.')) {
            return 'activation';
        }

        if (str_starts_with($action, 'expense.')) {
            return 'financial';
        }

        if (str_starts_with($action, 'device.')) {
            return 'devices';
        }

        if (in_array($action, ['register.created', 'login.success', 'login.failed', 'logout', 'instructor.password_set'], true)) {
            return 'auth';
        }

        if (str_starts_with($action, 'announcement.') || str_starts_with($action, 'notification.')) {
            return 'content';
        }

        return 'users';
    }

    /**
     * @return array<string, string>
     */
    public static function categoryOptions(): array
    {
        return self::CATEGORY_LABELS;
    }

    public static function categoryLabel(string $category): string
    {
        return self::CATEGORY_LABELS[$category] ?? $category;
    }

    public static function settingsGroupLabel(string $group): string
    {
        return self::SETTINGS_GROUP_LABELS[$group] ?? $group;
    }

    public static function displayDescription(AuditLog $record): string
    {
        $description = trim((string) ($record->description ?? ''));

        if ($description === '') {
            return '—';
        }

        if (preg_match('/^Updated ([a-z_]+) settings\.$/', $description, $matches)) {
            return 'تم تحديث إعدادات '.self::settingsGroupLabel($matches[1]).'.';
        }

        return match ($description) {
            'Maintenance mode enabled.' => 'تم تفعيل وضع الصيانة.',
            'Maintenance mode disabled.' => 'تم تعطيل وضع الصيانة.',
            'User logged out' => 'تم تسجيل الخروج.',
            'Instructor set password via invitation.' => 'قام المدرس بتعيين كلمة المرور عبر الدعوة.',
            default => self::translateLegacyDescription($description),
        };
    }

    public static function modelLabel(AuditLog $record): string
    {
        if ($record->model_type !== null) {
            $basename = class_basename($record->model_type);

            return self::MODEL_LABELS[$basename] ?? $basename;
        }

        if (preg_match('/^settings\.([a-z_]+)\.updated$/', $record->action, $matches)) {
            return 'إعدادات · '.self::settingsGroupLabel($matches[1]);
        }

        if ($record->action === 'settings.group.updated') {
            if (preg_match('/^Updated ([a-z_]+) settings\.$/', (string) $record->description, $matches)) {
                return 'إعدادات · '.self::settingsGroupLabel($matches[1]);
            }

            return 'إعدادات';
        }

        if ($record->action === 'maintenance.updated') {
            return 'المنصة';
        }

        return '—';
    }

    private static function translateLegacyDescription(string $description): string
    {
        if (preg_match('/^Successful login for (.+)$/', $description, $matches)) {
            return 'دخول ناجح للحساب «'.$matches[1].'».';
        }

        if (preg_match('/^Failed login attempt for (.+)$/', $description, $matches)) {
            return 'محاولة دخول فاشلة للحساب «'.$matches[1].'».';
        }

        if (preg_match('/^Student registered: (.+)$/', $description, $matches)) {
            return 'تم تسجيل الطالب «'.$matches[1].'».';
        }

        if (preg_match('/^Reset student devices for «(.+)»\.$/', $description, $matches)) {
            return 'تم إعادة تعيين أجهزة الطالب «'.$matches[1].'».';
        }

        if (preg_match('/^Purchase requested for subject «(.+)»\.$/', $description, $matches)) {
            return 'طلب تفعيل مادة «'.$matches[1].'».';
        }

        if (preg_match('/^Activated subject «(.+)» for student «(.+)»\.$/', $description, $matches)) {
            return 'تم تفعيل مادة «'.$matches[1].'» للطالب «'.$matches[2].'».';
        }

        if (preg_match('/^Revoked access to subject «(.+)» for student «(.+)»\.$/', $description, $matches)) {
            return 'تم إلغاء تفعيل مادة «'.$matches[1].'» للطالب «'.$matches[2].'».';
        }

        return $description;
    }
}
