@php
    /** @var \App\Filament\Pages\AccountingSummary $this */
@endphp

<div class="rshd-print-sheet">
    <header class="rshd-print-sheet__header">
        <div class="rshd-print-sheet__brand">
            <span class="rshd-print-sheet__logo">RSHD</span>
            <span class="rshd-print-sheet__brand-sub">Academy</span>
        </div>
        <div class="rshd-print-sheet__heading">
            <h1>ملخص الأرباح</h1>
            <p>تقرير مالي — {{ $activePeriodLabel }}</p>
        </div>
        <div class="rshd-print-sheet__meta">
            <div><span>الفترة</span><strong>{{ $periodRangeLabel }}</strong></div>
            <div><span>تاريخ الطباعة</span><strong>{{ now()->format('Y-m-d H:i') }}</strong></div>
            <div><span>أُعد بواسطة</span><strong>{{ $user?->name ?? '—' }}</strong></div>
        </div>
    </header>

    <section class="rshd-print-sheet__kpis">
        @foreach ($statCards as $card)
            <div class="rshd-print-sheet__kpi rshd-print-sheet__kpi--{{ $card['tone'] }}">
                <span class="rshd-print-sheet__kpi-value">{{ $card['value'] }}</span>
                <span class="rshd-print-sheet__kpi-label">{{ $card['label'] }}</span>
            </div>
        @endforeach
    </section>

    <section class="rshd-print-sheet__block">
        <h2 class="rshd-print-sheet__section-title">عمليات التفعيل (الإيرادات)</h2>
        <table class="rshd-print-sheet__table">
            <thead>
                <tr>
                    <th>#</th>
                    <th>الطالب</th>
                    <th>المادة</th>
                    <th>السعر</th>
                    <th>تاريخ التفعيل</th>
                    <th>تم بواسطة</th>
                </tr>
            </thead>
            <tbody>
                @forelse ($data['latestRevenues'] as $index => $row)
                    <tr>
                        <td>{{ $index + 1 }}</td>
                        <td>{{ $row->student?->name ?? '—' }}</td>
                        <td>{{ $row->subject?->title ?? '—' }}</td>
                        <td>{{ $this->formatMoney($row->sale_price) }}</td>
                        <td>{{ optional($row->paid_at ?? $row->activated_at ?? $row->created_at)?->format('Y-m-d') ?? '—' }}</td>
                        <td>{{ $row->activatedBy?->name ?? '—' }}</td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="6" class="rshd-print-sheet__empty">لا توجد عمليات تفعيل في الفترة المحددة.</td>
                    </tr>
                @endforelse
            </tbody>
            @if ($data['latestRevenues']->isNotEmpty())
                <tfoot>
                    <tr>
                        <td colspan="3"><strong>إجمالي الإيرادات</strong></td>
                        <td colspan="3"><strong>{{ $this->formatMoney($data['totalRevenue']) }}</strong></td>
                    </tr>
                </tfoot>
            @endif
        </table>
    </section>

    <div class="rshd-print-sheet__closing">
        <section class="rshd-print-sheet__block">
            <h2 class="rshd-print-sheet__section-title">المصاريف</h2>
            <table class="rshd-print-sheet__table">
            <thead>
                <tr>
                    <th>#</th>
                    <th>العنوان</th>
                    <th>المبلغ</th>
                    <th>التصنيف</th>
                    <th>التاريخ</th>
                    <th>الملاحظة</th>
                </tr>
            </thead>
            <tbody>
                @forelse ($data['latestExpenses'] as $index => $expense)
                    <tr>
                        <td>{{ $index + 1 }}</td>
                        <td>{{ $expense->title }}</td>
                        <td>{{ $this->formatMoney($expense->amount) }}</td>
                        <td>{{ $expense->category ?? '—' }}</td>
                        <td>{{ optional($expense->expense_date)?->format('Y-m-d') ?? '—' }}</td>
                        <td>{{ $expense->description ?: '—' }}</td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="6" class="rshd-print-sheet__empty">لا توجد مصاريف في الفترة المحددة.</td>
                    </tr>
                @endforelse
            </tbody>
            @if ($data['latestExpenses']->isNotEmpty())
                <tfoot>
                    <tr>
                        <td colspan="2"><strong>إجمالي المصاريف</strong></td>
                        <td colspan="4"><strong>{{ $this->formatMoney($data['totalExpenses']) }}</strong></td>
                    </tr>
                </tfoot>
            @endif
        </table>
        </section>

        <footer class="rshd-print-sheet__summary">
        <div class="rshd-print-sheet__summary-item">
            <span>عمليات البيع / التفعيل</span>
            <strong>{{ number_format($data['salesCount']) }}</strong>
        </div>
        <div class="rshd-print-sheet__summary-item">
            <span>إجمالي الإيرادات</span>
            <strong>{{ $this->formatMoney($data['totalRevenue']) }}</strong>
        </div>
        <div class="rshd-print-sheet__summary-item">
            <span>إجمالي المصاريف</span>
            <strong>{{ $this->formatMoney($data['totalExpenses']) }}</strong>
        </div>
        <div class="rshd-print-sheet__summary-item rshd-print-sheet__summary-item--highlight">
            <span>صافي الربح</span>
            <strong>{{ $this->formatMoney($data['netProfit']) }}</strong>
        </div>
    </footer>

        <p class="rshd-print-sheet__footnote">
            هذا التقرير صادر من نظام RSHD Academy — للاستخدام الداخلي فقط.
        </p>
    </div>
</div>
