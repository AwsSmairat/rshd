<?php

namespace App\Services;

use App\Enums\AccessStatus;
use App\Enums\PaymentStatus;
use App\Models\Expense;
use App\Models\SubjectStudent;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

class AccountingSummaryService
{
    public const PERIOD_TODAY = 'today';

    public const PERIOD_WEEK = 'week';

    public const PERIOD_MONTH = 'month';

    public const PERIOD_YEAR = 'year';

    public const PERIOD_CUSTOM = 'custom';

    /**
     * @return array{
     *     period: string,
     *     from: Carbon,
     *     to: Carbon,
     *     salesCount: int,
     *     totalRevenue: float,
     *     totalExpenses: float,
     *     netProfit: float,
     *     latestRevenues: Collection<int, SubjectStudent>,
     *     latestExpenses: Collection<int, Expense>,
     *     chartLabels: list<string>,
     *     chartRevenue: list<float>,
     *     chartExpenses: list<float>
     * }
     */
    public function build(
        string $period = self::PERIOD_MONTH,
        ?Carbon $customFrom = null,
        ?Carbon $customTo = null,
    ): array {
        [$from, $to] = $this->resolveRange($period, $customFrom, $customTo);

        $revenueQuery = $this->paidActivationsQuery($from, $to);
        $expenseQuery = $this->expensesQuery($from, $to);

        $totalRevenue = (float) (clone $revenueQuery)->sum('sale_price');
        $totalExpenses = (float) (clone $expenseQuery)->sum('amount');
        $salesCount = (int) (clone $revenueQuery)->count();

        return [
            'period' => $period,
            'from' => $from,
            'to' => $to,
            'salesCount' => $salesCount,
            'totalRevenue' => $totalRevenue,
            'totalExpenses' => $totalExpenses,
            'netProfit' => $totalRevenue - $totalExpenses,
            'latestRevenues' => (clone $revenueQuery)
                ->with(['student', 'subject', 'activatedBy'])
                ->orderByRaw('COALESCE(paid_at, activated_at, created_at) DESC')
                ->limit(10)
                ->get(),
            'latestExpenses' => (clone $expenseQuery)
                ->with('createdBy')
                ->orderByDesc('expense_date')
                ->orderByDesc('id')
                ->limit(10)
                ->get(),
            ...$this->chartSeries($from, $to, $period),
        ];
    }

    /**
     * @return array{0: Carbon, 1: Carbon}
     */
    public function resolveRange(
        string $period,
        ?Carbon $customFrom = null,
        ?Carbon $customTo = null,
    ): array {
        $now = now();

        return match ($period) {
            self::PERIOD_TODAY => [$now->copy()->startOfDay(), $now->copy()->endOfDay()],
            self::PERIOD_WEEK => [$now->copy()->startOfWeek(), $now->copy()->endOfWeek()],
            self::PERIOD_YEAR => [$now->copy()->startOfYear(), $now->copy()->endOfYear()],
            self::PERIOD_CUSTOM => [
                ($customFrom ?? $now->copy()->startOfMonth())->copy()->startOfDay(),
                ($customTo ?? $now)->copy()->endOfDay(),
            ],
            default => [$now->copy()->startOfMonth(), $now->copy()->endOfMonth()],
        };
    }

    /**
     * @return array{
     *     chartLabels: list<string>,
     *     chartRevenue: list<float>,
     *     chartExpenses: list<float>
     * }
     */
    protected function chartSeries(Carbon $from, Carbon $to, string $period): array
    {
        $effectiveEnd = $this->effectiveChartEnd($from, $to, $period);

        if ($period === self::PERIOD_YEAR) {
            return $this->monthlyChartSeries($from, $effectiveEnd);
        }

        $daySpan = $from->copy()->startOfDay()->diffInDays($effectiveEnd->copy()->startOfDay()) + 1;

        if ($daySpan > 45) {
            return $this->monthlyChartSeries($from, $effectiveEnd);
        }

        return $this->dailyChartSeries($from, $effectiveEnd);
    }

    protected function effectiveChartEnd(Carbon $from, Carbon $to, string $period): Carbon
    {
        $end = $to->copy()->endOfDay();

        if (in_array($period, [self::PERIOD_TODAY, self::PERIOD_WEEK, self::PERIOD_MONTH, self::PERIOD_YEAR], true)) {
            $end = $end->min(now()->endOfDay());
        }

        if ($period === self::PERIOD_CUSTOM && $to->isFuture()) {
            $end = now()->endOfDay();
        }

        return $end->max($from->copy()->endOfDay());
    }

    /**
     * @return array{
     *     chartLabels: list<string>,
     *     chartRevenue: list<float>,
     *     chartExpenses: list<float>
     * }
     */
    protected function dailyChartSeries(Carbon $from, Carbon $to): array
    {
        $labels = [];
        $revenue = [];
        $expenses = [];

        $cursor = $from->copy()->startOfDay();

        while ($cursor->lte($to)) {
            $dayStart = $cursor->copy()->startOfDay();
            $dayEnd = $cursor->copy()->endOfDay();

            $labels[] = $cursor->format('m/d');
            $revenue[] = (float) $this->paidActivationsQuery($dayStart, $dayEnd)->sum('sale_price');
            $expenses[] = (float) $this->expensesQuery($dayStart, $dayEnd)->sum('amount');

            $cursor->addDay();
        }

        return [
            'chartLabels' => $labels,
            'chartRevenue' => $revenue,
            'chartExpenses' => $expenses,
        ];
    }

    /**
     * @return array{
     *     chartLabels: list<string>,
     *     chartRevenue: list<float>,
     *     chartExpenses: list<float>
     * }
     */
    protected function monthlyChartSeries(Carbon $from, Carbon $to): array
    {
        $labels = [];
        $revenue = [];
        $expenses = [];

        $cursor = $from->copy()->startOfMonth();

        while ($cursor->lte($to)) {
            $monthStart = $cursor->copy()->startOfMonth()->max($from->copy()->startOfDay());
            $monthEnd = $cursor->copy()->endOfMonth()->min($to);

            $labels[] = $cursor->translatedFormat('M y');
            $revenue[] = (float) $this->paidActivationsQuery($monthStart, $monthEnd)->sum('sale_price');
            $expenses[] = (float) $this->expensesQuery($monthStart, $monthEnd)->sum('amount');

            $cursor->addMonth()->startOfMonth();
        }

        return [
            'chartLabels' => $labels,
            'chartRevenue' => $revenue,
            'chartExpenses' => $expenses,
        ];
    }

    protected function paidActivationsQuery(?Carbon $from = null, ?Carbon $to = null)
    {
        $query = SubjectStudent::query()
            ->where('payment_status', PaymentStatus::Paid)
            ->where('access_status', AccessStatus::Active);

        if ($from !== null && $to !== null) {
            $query->whereRaw(
                'COALESCE(paid_at, activated_at, created_at) BETWEEN ? AND ?',
                [$from, $to],
            );
        }

        return $query;
    }

    protected function expensesQuery(?Carbon $from = null, ?Carbon $to = null)
    {
        $query = Expense::query();

        if ($from !== null && $to !== null) {
            $query->whereBetween('expense_date', [
                $from->toDateString(),
                $to->toDateString(),
            ]);
        }

        return $query;
    }

    public static function formatMoney(float|int|string|null $amount): string
    {
        $symbol = (string) (app(PlatformSettingsService::class)->get('currency_symbol', 'د.أ', 'platform') ?: 'د.أ');

        return number_format((float) ($amount ?? 0), 2).' '.$symbol;
    }
}
