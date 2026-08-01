<?php

namespace App\Services;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\PaymentStatus;
use App\Enums\UserRole;
use App\Models\Announcement;
use App\Models\AssignmentSubmission;
use App\Models\Expense;
use App\Models\StudentDevice;
use App\Models\Subject;
use App\Models\SubjectStudent;
use App\Models\User;
use App\Models\Video;
use App\Services\PlatformSettingsService;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

class AdminDashboardService
{
    /**
     * @return array{
     *     stats: array<string, mixed>,
     *     pendingActivations: Collection<int, SubjectStudent>,
     *     recentActivities: Collection<int, array{title: string, time: Carbon, tone: string}>,
     *     finance: array<string, mixed>,
     *     alerts: Collection<int, array{title: string, count: int, tone: string, url: string|null}>
     * }
     */
    public function build(): array
    {
        $monthFrom = now()->copy()->startOfMonth();
        $monthTo = now()->copy()->endOfMonth();
        $prevFrom = now()->copy()->subMonth()->startOfMonth();
        $prevTo = now()->copy()->subMonth()->endOfMonth();

        $monthly = app(AccountingSummaryService::class)->build(
            AccountingSummaryService::PERIOD_MONTH,
        );
        $previousRevenue = (float) $this->paidActivationsBetween($prevFrom, $prevTo)->sum('sale_price');
        $previousExpenses = (float) Expense::query()
            ->whereBetween('expense_date', [$prevFrom->toDateString(), $prevTo->toDateString()])
            ->sum('amount');
        $previousNet = $previousRevenue - $previousExpenses;

        return [
            'stats' => $this->stats($monthly, $previousRevenue, $previousNet),
            'pendingActivations' => $this->pendingActivations(),
            'recentActivities' => $this->recentActivities(),
            'finance' => [
                'revenue' => $monthly['totalRevenue'],
                'expenses' => $monthly['totalExpenses'],
                'netProfit' => $monthly['netProfit'],
                'revenueChange' => $this->percentChange($monthly['totalRevenue'], $previousRevenue),
                'expensesChange' => $this->percentChange($monthly['totalExpenses'], $previousExpenses),
                'netChange' => $this->percentChange($monthly['netProfit'], $previousNet),
                'chartLabels' => $this->lastMonthsLabels(6),
                'chartRevenue' => $this->lastMonthsRevenue(6),
                'chartExpenses' => $this->lastMonthsExpenses(6),
            ],
            'alerts' => $this->alerts(),
            'settings' => [
                'manualActivationRequired' => app(PlatformSettingsService::class)->enabled('manual_activation_required', 'payments'),
                'inAppNotificationsEnabled' => app(PlatformSettingsService::class)->enabled('in_app_notifications_enabled', 'notifications'),
            ],
        ];
    }

    /**
     * @param  array<string, mixed>  $monthly
     * @return array<string, mixed>
     */
    protected function stats(array $monthly, float $previousRevenue, float $previousNet): array
    {
        $pendingThisMonth = SubjectStudent::query()
            ->where(function ($q): void {
                $q->where('access_status', AccessStatus::Pending)
                    ->orWhere(function ($inner): void {
                        $inner->where('payment_status', PaymentStatus::Unpaid)
                            ->where('access_status', '!=', AccessStatus::Active);
                    });
            })
            ->where('created_at', '>=', now()->startOfMonth())
            ->count();

        return [
            'students' => User::query()->where('role', UserRole::Student)->count(),
            'studentsThisMonth' => User::query()
                ->where('role', UserRole::Student)
                ->where('created_at', '>=', now()->startOfMonth())
                ->count(),
            'instructors' => User::query()->where('role', UserRole::Instructor)->count(),
            'instructorsThisMonth' => User::query()
                ->where('role', UserRole::Instructor)
                ->where('created_at', '>=', now()->startOfMonth())
                ->count(),
            'activeSubjects' => Subject::query()->where('status', ContentStatus::Active)->count(),
            'activeSubjectsThisMonth' => Subject::query()
                ->where('status', ContentStatus::Active)
                ->where('created_at', '>=', now()->startOfMonth())
                ->count(),
            'pendingActivations' => $this->pendingActivationsQuery()->count(),
            'pendingThisMonth' => $pendingThisMonth,
            'monthlyRevenue' => $monthly['totalRevenue'],
            'netProfit' => $monthly['netProfit'],
            'revenueChange' => $this->percentChange($monthly['totalRevenue'], $previousRevenue),
            'netChange' => $this->percentChange($monthly['netProfit'], $previousNet),
        ];
    }

    /**
     * @return Collection<int, SubjectStudent>
     */
    protected function pendingActivations(): Collection
    {
        return $this->pendingActivationsQuery()
            ->with(['student', 'subject'])
            ->orderByDesc('created_at')
            ->limit(8)
            ->get();
    }

    protected function pendingActivationsQuery()
    {
        return SubjectStudent::query()
            ->where(function ($q): void {
                $q->where('access_status', AccessStatus::Pending)
                    ->orWhere(function ($inner): void {
                        $inner->where('payment_status', PaymentStatus::Unpaid)
                            ->where('access_status', '!=', AccessStatus::Active)
                            ->where('access_status', '!=', AccessStatus::Revoked);
                    });
            });
    }

    /**
     * @return Collection<int, array{title: string, time: Carbon, tone: string}>
     */
    protected function recentActivities(): Collection
    {
        $items = collect();

        User::query()
            ->where('role', UserRole::Student)
            ->latest()
            ->limit(5)
            ->get()
            ->each(function (User $user) use ($items): void {
                $items->push([
                    'title' => 'طالب جديد سجّل: '.$user->name,
                    'time' => $user->created_at ?? now(),
                    'tone' => 'success',
                ]);
            });

        SubjectStudent::query()
            ->with(['student', 'subject'])
            ->where('payment_status', PaymentStatus::Paid)
            ->where('access_status', AccessStatus::Active)
            ->orderByRaw('COALESCE(activated_at, paid_at, created_at) DESC')
            ->limit(5)
            ->get()
            ->each(function (SubjectStudent $row) use ($items): void {
                $items->push([
                    'title' => 'تم تفعيل مادة «'.($row->subject?->title ?? '—').'» للطالب '.($row->student?->name ?? '—'),
                    'time' => $row->activated_at ?? $row->paid_at ?? $row->created_at ?? now(),
                    'tone' => 'info',
                ]);
            });

        Video::query()
            ->latest()
            ->limit(5)
            ->get()
            ->each(function (Video $video) use ($items): void {
                $items->push([
                    'title' => 'تم رفع فيديو: '.$video->title,
                    'time' => $video->created_at ?? now(),
                    'tone' => 'purple',
                ]);
            });

        AssignmentSubmission::query()
            ->with(['student', 'assignment'])
            ->latest('submitted_at')
            ->limit(5)
            ->get()
            ->each(function (AssignmentSubmission $submission) use ($items): void {
                $items->push([
                    'title' => 'تم تسليم واجب: '.($submission->assignment?->title ?? '—'),
                    'time' => $submission->submitted_at ?? $submission->created_at ?? now(),
                    'tone' => 'warning',
                ]);
            });

        Announcement::query()
            ->latest()
            ->limit(5)
            ->get()
            ->each(function (Announcement $announcement) use ($items): void {
                $items->push([
                    'title' => 'تم نشر إعلان: '.$announcement->title,
                    'time' => $announcement->created_at ?? now(),
                    'tone' => 'gold',
                ]);
            });

        return $items
            ->sortByDesc(fn (array $item) => $item['time']?->timestamp ?? 0)
            ->values()
            ->take(5);
    }

    /**
     * @return Collection<int, array{title: string, count: int, tone: string, url: string|null}>
     */
    protected function alerts(): Collection
    {
        $unverified = User::query()
            ->where('role', UserRole::Student)
            ->whereNull('email_verified_at')
            ->count();

        $pendingSubmissions = AssignmentSubmission::query()
            ->whereNull('grade')
            ->count();

        $inactiveDevices = StudentDevice::query()
            ->where('is_active', false)
            ->count();

        $pendingActivations = $this->pendingActivationsQuery()->count();

        return collect([
            [
                'title' => 'طلاب غير مؤكدين البريد',
                'count' => $unverified,
                'tone' => 'danger',
                'key' => 'unverified',
            ],
            [
                'title' => 'تسليمات تحتاج مراجعة',
                'count' => $pendingSubmissions,
                'tone' => 'warning',
                'key' => 'submissions',
            ],
            [
                'title' => 'أجهزة غير نشطة / إعادة تعيين',
                'count' => $inactiveDevices,
                'tone' => 'info',
                'key' => 'devices',
            ],
            [
                'title' => 'طلبات تفعيل بانتظار الموافقة',
                'count' => $pendingActivations,
                'tone' => 'gold',
                'key' => 'activations',
            ],
        ])->filter(fn (array $alert): bool => $alert['count'] > 0)->values();
    }

    protected function paidActivationsBetween(Carbon $from, Carbon $to)
    {
        return SubjectStudent::query()
            ->where('payment_status', PaymentStatus::Paid)
            ->where('access_status', AccessStatus::Active)
            ->whereRaw('COALESCE(paid_at, created_at) BETWEEN ? AND ?', [$from, $to]);
    }

    /**
     * @return list<string>
     */
    protected function lastMonthsLabels(int $count): array
    {
        $labels = [];
        for ($i = $count - 1; $i >= 0; $i--) {
            $labels[] = now()->copy()->subMonths($i)->translatedFormat('M');
        }

        return $labels;
    }

    /**
     * @return list<float>
     */
    protected function lastMonthsRevenue(int $count): array
    {
        $values = [];
        for ($i = $count - 1; $i >= 0; $i--) {
            $from = now()->copy()->subMonths($i)->startOfMonth();
            $to = now()->copy()->subMonths($i)->endOfMonth();
            $values[] = (float) $this->paidActivationsBetween($from, $to)->sum('sale_price');
        }

        return $values;
    }

    /**
     * @return list<float>
     */
    protected function lastMonthsExpenses(int $count): array
    {
        $values = [];
        for ($i = $count - 1; $i >= 0; $i--) {
            $from = now()->copy()->subMonths($i)->startOfMonth();
            $to = now()->copy()->subMonths($i)->endOfMonth();
            $values[] = (float) Expense::query()
                ->whereBetween('expense_date', [$from->toDateString(), $to->toDateString()])
                ->sum('amount');
        }

        return $values;
    }

    protected function percentChange(float $current, float $previous): ?float
    {
        if ($previous == 0.0) {
            return $current > 0 ? 100.0 : null;
        }

        return round((($current - $previous) / abs($previous)) * 100, 1);
    }
}
