<?php

namespace App\Services;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\PaymentStatus;
use App\Enums\UserRole;
use App\Models\Expense;
use App\Models\Subject;
use App\Models\SubjectStudent;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class ReportsService
{
    public function __construct(
        protected AccountingSummaryService $accounting,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function build(
        string $period = AccountingSummaryService::PERIOD_MONTH,
        ?Carbon $customFrom = null,
        ?Carbon $customTo = null,
    ): array {
        $summary = $this->accounting->build($period, $customFrom, $customTo);
        [$from, $to] = [$summary['from'], $summary['to']];

        return [
            ...$summary,
            'topSubjects' => $this->topSubjectsByRevenue($from, $to),
            'expensesByCategory' => $this->expensesByCategory($from, $to),
            'activations' => $this->activationsInPeriod($from, $to),
            'newStudents' => User::query()
                ->where('role', UserRole::Student)
                ->whereBetween('created_at', [$from, $to])
                ->count(),
            'activeSubjects' => Subject::query()->where('status', ContentStatus::Active)->count(),
            'pendingActivations' => SubjectStudent::query()
                ->where(function ($q): void {
                    $q->where('access_status', AccessStatus::Pending)
                        ->orWhere(function ($inner): void {
                            $inner->where('payment_status', PaymentStatus::Unpaid)
                                ->where('access_status', '!=', AccessStatus::Active)
                                ->where('access_status', '!=', AccessStatus::Revoked);
                        });
                })
                ->count(),
        ];
    }

    /**
     * @return Collection<int, object{subject_id: int, title: string, sales_count: int, revenue: float}>
     */
    protected function topSubjectsByRevenue(Carbon $from, Carbon $to): Collection
    {
        return SubjectStudent::query()
            ->select([
                'subject_id',
                DB::raw('COUNT(*) as sales_count'),
                DB::raw('COALESCE(SUM(sale_price), 0) as revenue'),
            ])
            ->where('payment_status', PaymentStatus::Paid)
            ->where('access_status', AccessStatus::Active)
            ->whereRaw('COALESCE(paid_at, created_at) BETWEEN ? AND ?', [$from, $to])
            ->groupBy('subject_id')
            ->orderByDesc('revenue')
            ->limit(8)
            ->get()
            ->map(function ($row) {
                $subject = Subject::query()->find($row->subject_id);

                return (object) [
                    'subject_id' => (int) $row->subject_id,
                    'title' => $subject?->title ?? '—',
                    'sales_count' => (int) $row->sales_count,
                    'revenue' => (float) $row->revenue,
                ];
            });
    }

    /**
     * @return Collection<int, object{category: string, total: float, count: int}>
     */
    protected function expensesByCategory(Carbon $from, Carbon $to): Collection
    {
        return Expense::query()
            ->select([
                DB::raw("COALESCE(category, 'أخرى') as category"),
                DB::raw('COALESCE(SUM(amount), 0) as total'),
                DB::raw('COUNT(*) as count'),
            ])
            ->whereBetween('expense_date', [$from->toDateString(), $to->toDateString()])
            ->groupBy(DB::raw("COALESCE(category, 'أخرى')"))
            ->orderByDesc('total')
            ->get()
            ->map(fn ($row) => (object) [
                'category' => (string) $row->category,
                'total' => (float) $row->total,
                'count' => (int) $row->count,
            ]);
    }

    /**
     * @return Collection<int, SubjectStudent>
     */
    protected function activationsInPeriod(Carbon $from, Carbon $to): Collection
    {
        return SubjectStudent::query()
            ->with(['student', 'subject', 'activatedBy'])
            ->where('payment_status', PaymentStatus::Paid)
            ->where('access_status', AccessStatus::Active)
            ->whereRaw('COALESCE(paid_at, created_at) BETWEEN ? AND ?', [$from, $to])
            ->orderByRaw('COALESCE(paid_at, created_at) DESC')
            ->limit(20)
            ->get();
    }
}
