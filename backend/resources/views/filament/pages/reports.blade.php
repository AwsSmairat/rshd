@php
    /** @var \App\Filament\Pages\Reports $this */
    $data = $this->reportData();
    $periods = [
        'today' => 'اليوم',
        'week' => 'هذا الأسبوع',
        'month' => 'هذا الشهر',
        'year' => 'هذا العام',
        'custom' => 'مخصص',
    ];
    $maxChart = max(1, max($data['chartRevenue'] ?: [0]), max($data['chartExpenses'] ?: [0]));
@endphp

<x-filament-panels::page>
    <div class="rshd-reports-page">
        <section class="rshd-dash-header">
            <div class="rshd-dash-header__content">
                <div class="rshd-dash-header__welcome">
                    <h1>التقارير</h1>
                    <p>
                        تقرير الفترة:
                        {{ $data['from']->format('Y-m-d') }}
                        —
                        {{ $data['to']->format('Y-m-d') }}
                    </p>
                </div>
                <div class="rshd-dash-header__actions">
                    <a href="{{ $this->accountingSummaryUrl() }}" class="rshd-logout-btn" style="text-decoration:none">
                        ملخص الأرباح
                    </a>
                </div>
            </div>
            <div class="rshd-dash-header__ornament" aria-hidden="true"></div>
        </section>

        <section class="rshd-accounting-filters">
            <div class="rshd-period-tabs">
                @foreach ($periods as $key => $label)
                    <button
                        type="button"
                        wire:click="setPeriod('{{ $key }}')"
                        @class(['rshd-period-tab', 'is-active' => $period === $key])
                    >
                        {{ $label }}
                    </button>
                @endforeach
            </div>

            @if ($period === 'custom')
                <div class="rshd-custom-range">
                    <label>
                        <span>من تاريخ</span>
                        <input type="date" wire:model.live="customFrom">
                    </label>
                    <label>
                        <span>إلى تاريخ</span>
                        <input type="date" wire:model.live="customTo">
                    </label>
                </div>
            @endif
        </section>

        <section class="rshd-accounting-stats-grid">
            <article class="rshd-stat-card rshd-stat-card--gold">
                <div class="rshd-stat-card__body">
                    <div class="rshd-stat-card__value">{{ $this->formatMoney($data['totalRevenue']) }}</div>
                    <div class="rshd-stat-card__label">إجمالي الإيرادات</div>
                </div>
            </article>
            <article class="rshd-stat-card rshd-stat-card--danger">
                <div class="rshd-stat-card__body">
                    <div class="rshd-stat-card__value">{{ $this->formatMoney($data['totalExpenses']) }}</div>
                    <div class="rshd-stat-card__label">إجمالي المصاريف</div>
                </div>
            </article>
            <article class="rshd-stat-card rshd-stat-card--success">
                <div class="rshd-stat-card__body">
                    <div class="rshd-stat-card__value">{{ $this->formatMoney($data['netProfit']) }}</div>
                    <div class="rshd-stat-card__label">صافي الربح</div>
                </div>
            </article>
            <article class="rshd-stat-card rshd-stat-card--navy">
                <div class="rshd-stat-card__body">
                    <div class="rshd-stat-card__value">{{ number_format($data['salesCount']) }}</div>
                    <div class="rshd-stat-card__label">عمليات التفعيل</div>
                </div>
            </article>
        </section>

        <section class="rshd-reports-kpis">
            <article class="rshd-panel">
                <div class="rshd-panel__body">
                    <div class="rshd-reports-kpi">
                        <span>طلاب جدد في الفترة</span>
                        <strong>{{ number_format($data['newStudents']) }}</strong>
                    </div>
                </div>
            </article>
            <article class="rshd-panel">
                <div class="rshd-panel__body">
                    <div class="rshd-reports-kpi">
                        <span>المواد النشطة</span>
                        <strong>{{ number_format($data['activeSubjects']) }}</strong>
                    </div>
                </div>
            </article>
            <article class="rshd-panel">
                <div class="rshd-panel__body">
                    <div class="rshd-reports-kpi">
                        <span>طلبات بانتظار التفعيل</span>
                        <strong>{{ number_format($data['pendingActivations']) }}</strong>
                        <a href="{{ $this->enrollmentsIndexUrl() }}" class="rshd-link-muted">عرض الطلبات</a>
                    </div>
                </div>
            </article>
            <article class="rshd-panel">
                <div class="rshd-panel__body">
                    <div class="rshd-reports-kpi">
                        <span>سجل المصاريف</span>
                        <strong>{{ $data['expensesByCategory']->sum('count') }}</strong>
                        <a href="{{ $this->expensesIndexUrl() }}" class="rshd-link-muted">إدارة المصاريف</a>
                    </div>
                </div>
            </article>
        </section>

        <section class="rshd-accounting-main-grid">
            <article class="rshd-panel rshd-panel--chart">
                <div class="rshd-panel__header">
                    <h2>الإيرادات والمصاريف خلال الفترة</h2>
                </div>
                <div class="rshd-panel__body">
                    <div class="rshd-chart-legend">
                        <span><i class="rshd-dot rshd-dot--gold"></i> الإيرادات</span>
                        <span><i class="rshd-dot rshd-dot--danger"></i> المصاريف</span>
                    </div>
                    <div class="rshd-simple-chart">
                        @forelse ($data['chartLabels'] as $index => $label)
                            <div class="rshd-simple-chart__group">
                                <div class="rshd-simple-chart__bars">
                                    <div
                                        class="rshd-simple-chart__bar rshd-simple-chart__bar--revenue"
                                        style="height: {{ (($data['chartRevenue'][$index] ?? 0) / $maxChart) * 100 }}%"
                                        title="{{ $this->formatMoney($data['chartRevenue'][$index] ?? 0) }}"
                                    ></div>
                                    <div
                                        class="rshd-simple-chart__bar rshd-simple-chart__bar--expense"
                                        style="height: {{ (($data['chartExpenses'][$index] ?? 0) / $maxChart) * 100 }}%"
                                        title="{{ $this->formatMoney($data['chartExpenses'][$index] ?? 0) }}"
                                    ></div>
                                </div>
                                <span class="rshd-simple-chart__label">{{ $label }}</span>
                            </div>
                        @empty
                            <div class="rshd-empty">لا توجد بيانات للفترة المحددة.</div>
                        @endforelse
                    </div>
                </div>
            </article>

            <article class="rshd-panel">
                <div class="rshd-panel__header">
                    <h2>أعلى المواد إيراداً</h2>
                </div>
                <div class="rshd-panel__body rshd-panel__body--table">
                    <div class="rshd-table-wrap">
                        <table class="rshd-table">
                            <thead>
                                <tr>
                                    <th>المادة</th>
                                    <th>التفعيلات</th>
                                    <th>الإيراد</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse ($data['topSubjects'] as $row)
                                    <tr>
                                        <td>{{ $row->title }}</td>
                                        <td>{{ number_format($row->sales_count) }}</td>
                                        <td>{{ $this->formatMoney($row->revenue) }}</td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="3" class="rshd-empty">لا توجد إيرادات في هذه الفترة.</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
            </article>
        </section>

        <section class="rshd-accounting-bottom-grid">
            <article class="rshd-panel">
                <div class="rshd-panel__header">
                    <h2>المصاريف حسب التصنيف</h2>
                </div>
                <div class="rshd-panel__body rshd-panel__body--table">
                    <div class="rshd-table-wrap">
                        <table class="rshd-table">
                            <thead>
                                <tr>
                                    <th>التصنيف</th>
                                    <th>العدد</th>
                                    <th>المبلغ</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse ($data['expensesByCategory'] as $row)
                                    <tr>
                                        <td>{{ $row->category }}</td>
                                        <td>{{ number_format($row->count) }}</td>
                                        <td>{{ $this->formatMoney($row->total) }}</td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="3" class="rshd-empty">لا توجد مصاريف في هذه الفترة.</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
            </article>

            <article class="rshd-panel">
                <div class="rshd-panel__header">
                    <h2>تفعيلات الفترة</h2>
                </div>
                <div class="rshd-panel__body rshd-panel__body--table">
                    <div class="rshd-table-wrap">
                        <table class="rshd-table">
                            <thead>
                                <tr>
                                    <th>الطالب</th>
                                    <th>المادة</th>
                                    <th>السعر</th>
                                    <th>التاريخ</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse ($data['activations'] as $row)
                                    <tr>
                                        <td>{{ $row->student?->name ?? '—' }}</td>
                                        <td>{{ $row->subject?->title ?? '—' }}</td>
                                        <td>{{ $this->formatMoney($row->sale_price) }}</td>
                                        <td>{{ optional($row->paid_at ?? $row->activated_at ?? $row->created_at)?->format('Y-m-d') ?? '—' }}</td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="4" class="rshd-empty">لا توجد تفعيلات في هذه الفترة.</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
            </article>
        </section>
    </div>
</x-filament-panels::page>
