<?php

namespace App\Filament\Pages;

use App\Filament\Resources\ExpenseResource;
use App\Filament\Resources\InstructorResource;
use App\Filament\Resources\NotificationResource;
use App\Filament\Resources\StudentResource;
use App\Filament\Resources\SubjectStudentResource;
use App\Models\User;
use App\Services\AccountingSummaryService;
use App\Services\PlatformSettingsService;
use Filament\Facades\Filament;
use Filament\Pages\Page;
use Illuminate\Contracts\Support\Htmlable;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Auth;
use Livewire\Attributes\Url;
use Symfony\Component\HttpFoundation\StreamedResponse;

class AccountingSummary extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-chart-bar-square';

    protected static ?string $navigationGroup = 'الرئيسية';

    protected static ?string $navigationLabel = 'ملخص الأرباح';

    protected static ?string $title = 'ملخص الأرباح';

    protected static ?int $navigationSort = -1;

    protected static string $view = 'filament.pages.accounting-summary';

    #[Url]
    public string $period = AccountingSummaryService::PERIOD_MONTH;

    #[Url]
    public ?string $customFrom = null;

    #[Url]
    public ?string $customTo = null;

    public function mount(): void
    {
        $allowed = [
            AccountingSummaryService::PERIOD_TODAY,
            AccountingSummaryService::PERIOD_WEEK,
            AccountingSummaryService::PERIOD_MONTH,
            AccountingSummaryService::PERIOD_YEAR,
            AccountingSummaryService::PERIOD_CUSTOM,
        ];

        if (! in_array($this->period, $allowed, true)) {
            $this->period = AccountingSummaryService::PERIOD_MONTH;
        }
    }

    public function isAdmin(): bool
    {
        return $this->authUser()?->isAdmin() ?? false;
    }

    public function roleLabel(): string
    {
        $user = $this->authUser();

        if ($user?->isAdmin()) {
            return 'مسؤول النظام';
        }

        if ($user?->isInstructor()) {
            return 'مدرس';
        }

        return 'مستخدم';
    }

    public function currencySymbol(): string
    {
        return (string) (app(PlatformSettingsService::class)->get('currency_symbol', 'د.أ', 'platform') ?: 'د.أ');
    }

    public static function canAccess(): bool
    {
        $user = auth()->user();

        if ($user?->isAdmin()) {
            return true;
        }

        return $user?->isInstructor()
            && app(PlatformSettingsService::class)->enabled('instructor_can_view_accounting', 'instructors');
    }

    public static function shouldRegisterNavigation(): bool
    {
        return static::canAccess();
    }

    public function getTitle(): string|Htmlable
    {
        return 'ملخص الأرباح';
    }

    public function getHeading(): string|Htmlable
    {
        return '';
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
        $first = mb_substr($parts[0] ?? '', 0, 1);
        $second = mb_substr($parts[1] ?? '', 0, 1);

        return mb_strtoupper($first.$second) ?: 'أ';
    }

    public function logoutUrl(): string
    {
        return Filament::getLogoutUrl();
    }

    public function notificationsUrl(): string
    {
        return NotificationResource::getUrl('index');
    }

    public function setPeriod(string $period): void
    {
        $this->period = $period;
    }

    /**
     * @return array<string, mixed>
     */
    public function summaryData(): array
    {
        return app(AccountingSummaryService::class)->build(
            $this->period,
            $this->customFrom ? Carbon::parse($this->customFrom) : null,
            $this->customTo ? Carbon::parse($this->customTo) : null,
        );
    }

    public function formatMoney(float|int|string|null $amount): string
    {
        return AccountingSummaryService::formatMoney($amount);
    }

    public function exportSummary(): StreamedResponse
    {
        $data = $this->summaryData();
        $filename = 'accounting-summary-'.$data['from']->format('Y-m-d').'_'.$data['to']->format('Y-m-d').'.csv';

        return response()->streamDownload(function () use ($data): void {
            $handle = fopen('php://output', 'w');

            if ($handle === false) {
                return;
            }

            fwrite($handle, "\xEF\xBB\xBF");

            fputcsv($handle, ['ملخص الأرباح']);
            fputcsv($handle, ['من', $data['from']->format('Y-m-d'), 'إلى', $data['to']->format('Y-m-d')]);
            fputcsv($handle, []);
            fputcsv($handle, ['عمليات البيع / التفعيل', $data['salesCount']]);
            fputcsv($handle, ['إجمالي الإيرادات', $data['totalRevenue']]);
            fputcsv($handle, ['إجمالي المصاريف', $data['totalExpenses']]);
            fputcsv($handle, ['صافي الربح', $data['netProfit']]);
            fputcsv($handle, []);
            fputcsv($handle, ['عمليات التفعيل (الإيرادات)']);
            fputcsv($handle, ['الطالب', 'المادة', 'السعر', 'تاريخ التفعيل', 'تم بواسطة']);

            foreach ($data['latestRevenues'] as $row) {
                fputcsv($handle, [
                    $row->student?->name ?? '—',
                    $row->subject?->title ?? '—',
                    $row->sale_price,
                    optional($row->paid_at ?? $row->activated_at ?? $row->created_at)?->format('Y-m-d H:i') ?? '—',
                    $row->activatedBy?->name ?? '—',
                ]);
            }

            fputcsv($handle, []);
            fputcsv($handle, ['المصاريف']);
            fputcsv($handle, ['العنوان', 'المبلغ', 'التصنيف', 'التاريخ', 'الملاحظة']);

            foreach ($data['latestExpenses'] as $expense) {
                fputcsv($handle, [
                    $expense->title,
                    $expense->amount,
                    $expense->category ?? '—',
                    optional($expense->expense_date)?->format('Y-m-d') ?? '—',
                    $expense->description ?: '—',
                ]);
            }

            fclose($handle);
        }, $filename, [
            'Content-Type' => 'text/csv; charset=UTF-8',
        ]);
    }

    /**
     * @return array<int, array{label: string, icon: string, url: string|null, enabled: bool, disabledReason: string|null}>
     */
    public function quickActions(): array
    {
        $settings = app(PlatformSettingsService::class);

        return [
            [
                'label' => 'تفعيل مادة لطالب',
                'icon' => 'clipboard',
                'url' => SubjectStudentResource::getUrl('create'),
                'enabled' => true,
                'disabledReason' => null,
            ],
            [
                'label' => 'طلبات التفعيل',
                'icon' => 'bolt',
                'url' => SubjectStudentResource::getUrl('index'),
                'enabled' => true,
                'disabledReason' => null,
            ],
            [
                'label' => 'إضافة مصروف',
                'icon' => 'file',
                'url' => ExpenseResource::getUrl('create'),
                'enabled' => auth()->user()?->isAdmin() ?? false,
                'disabledReason' => 'إضافة المصاريف متاحة للمسؤول فقط',
            ],
            [
                'label' => 'عرض التقارير',
                'icon' => 'quiz',
                'url' => Reports::getUrl(),
                'enabled' => auth()->user()?->isAdmin() ?? false,
                'disabledReason' => 'التقارير متاحة للمسؤول فقط',
            ],
            [
                'label' => 'إدارة الطلاب',
                'icon' => 'users',
                'url' => StudentResource::getUrl('index'),
                'enabled' => auth()->user()?->isAdmin() ?? false,
                'disabledReason' => 'إدارة الطلاب متاحة للمسؤول فقط',
            ],
            [
                'label' => 'إدارة المدرسين',
                'icon' => 'play',
                'url' => InstructorResource::getUrl('index'),
                'enabled' => auth()->user()?->isAdmin() ?? false,
                'disabledReason' => 'إدارة المدرسين متاحة للمسؤول فقط',
            ],
            [
                'label' => 'إرسال إشعار',
                'icon' => 'megaphone',
                'url' => NotificationResource::getUrl('create'),
                'enabled' => (auth()->user()?->isAdmin() ?? false)
                    && $settings->enabled('in_app_notifications_enabled', 'notifications'),
                'disabledReason' => auth()->user()?->isAdmin()
                    ? 'الإشعارات داخل التطبيق معطّلة في إعدادات المنصة'
                    : 'إرسال الإشعارات متاح للمسؤول فقط',
            ],
            [
                'label' => 'إعدادات النظام',
                'icon' => 'book',
                'url' => Settings::getUrl(),
                'enabled' => auth()->user()?->isAdmin() ?? false,
                'disabledReason' => 'إعدادات النظام متاحة للمسؤول فقط',
            ],
        ];
    }
}
