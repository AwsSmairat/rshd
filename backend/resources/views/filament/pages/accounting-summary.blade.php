@php
    /** @var \App\Filament\Pages\AccountingSummary $this */
    $data = $this->summaryData();
    $user = $this->authUser();
    $quickActions = $this->quickActions();

    $statCards = [
        [
            'key' => 'salesCount',
            'label' => 'عمليات البيع / التفعيل',
            'unit' => 'عملية',
            'icon' => 'clipboard',
            'tone' => 'navy',
            'value' => number_format($data['salesCount']),
        ],
        [
            'key' => 'totalRevenue',
            'label' => 'إجمالي الإيرادات',
            'unit' => $this->currencySymbol(),
            'icon' => 'book',
            'tone' => 'gold',
            'value' => number_format($data['totalRevenue'], 2),
        ],
        [
            'key' => 'totalExpenses',
            'label' => 'إجمالي المصاريف',
            'unit' => $this->currencySymbol(),
            'icon' => 'file',
            'tone' => 'danger',
            'value' => number_format($data['totalExpenses'], 2),
        ],
        [
            'key' => 'netProfit',
            'label' => 'صافي الربح',
            'unit' => $this->currencySymbol(),
            'icon' => 'bolt',
            'tone' => $data['netProfit'] > 0 ? 'success' : ($data['netProfit'] < 0 ? 'danger' : 'muted'),
            'value' => number_format($data['netProfit'], 2),
        ],
    ];

    $periods = [
        'today' => 'اليوم',
        'week' => 'هذا الأسبوع',
        'month' => 'هذا الشهر',
        'year' => 'هذا العام',
        'custom' => 'مخصص',
    ];

    $periodRangeLabel = $data['from']->format('Y-m-d').' — '.$data['to']->format('Y-m-d');
    $activePeriodLabel = $periods[$this->period] ?? $this->period;
    $maxChart = max(1, max($data['chartRevenue'] ?: [0]), max($data['chartExpenses'] ?: [0]));
    $chartHasValues = array_sum($data['chartRevenue'] ?: []) > 0 || array_sum($data['chartExpenses'] ?: []) > 0;
@endphp

<x-filament-panels::page>
    <div class="rshd-accounting-dashboard" id="rshd-accounting-print-area">
        @include('filament.pages.partials.accounting-summary-print', [
            'data' => $data,
            'statCards' => $statCards,
            'activePeriodLabel' => $activePeriodLabel,
            'periodRangeLabel' => $periodRangeLabel,
            'user' => $user,
        ])

        <div class="rshd-screen-only">
        <section class="rshd-dash-header rshd-dash-header--accounting rshd-no-print">
            <div class="rshd-dash-header__content">
                <div class="rshd-dash-header__welcome">
                    <h1>ملخص الأرباح</h1>
                    <p>نظرة عامة على الإيرادات والمصاريف وصافي الربح</p>
                </div>

                <div class="rshd-dash-header__actions rshd-dash-header__actions--compact rshd-no-print">
                    <button type="button" class="rshd-export-btn" wire:click="exportSummary">
                        تصدير
                    </button>

                    <button type="button" class="rshd-export-btn rshd-print-btn" onclick="window.print()">
                        طباعة
                    </button>

                    @if ($this->isAdmin())
                        <a href="{{ $this->notificationsUrl() }}" class="rshd-icon-btn" title="الإشعارات" aria-label="الإشعارات">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M15 17h5l-1.4-1.4A2 2 0 0 1 18 14.2V11a6 6 0 1 0-12 0v3.2c0 .5-.2 1-.6 1.4L4 17h5m6 0a3 3 0 1 1-6 0" />
                            </svg>
                        </a>
                    @endif

                    <div class="rshd-dash-header__profile">
                        <div class="rshd-dash-header__avatar">{{ $this->adminInitials() }}</div>
                        <div class="rshd-dash-header__meta">
                            <strong>{{ $user?->name }}</strong>
                            <span>{{ $this->roleLabel() }}</span>
                        </div>
                    </div>

                    <form method="POST" action="{{ $this->logoutUrl() }}">
                        @csrf
                        <button type="submit" class="rshd-logout-btn">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0 0 13.5 3h-6A2.25 2.25 0 0 0 5.25 5.25v13.5A2.25 2.25 0 0 0 7.5 21h6a2.25 2.25 0 0 0 2.25-2.25V15M12 9l3 3m0 0-3 3m3-3H3" />
                            </svg>
                        </button>
                    </form>
                </div>
            </div>
            <div class="rshd-dash-header__ornament rshd-no-print" aria-hidden="true"></div>
        </section>

        <section class="rshd-accounting-filters rshd-no-print">
            <div class="rshd-period-tabs">
                @foreach ($periods as $key => $label)
                    <button
                        type="button"
                        wire:click="setPeriod('{{ $key }}')"
                        @class(['rshd-period-tab', 'is-active' => $this->period === $key])
                    >
                        {{ $label }}
                    </button>
                @endforeach
            </div>

            <span class="rshd-accounting-filters__range">{{ $activePeriodLabel }} · {{ $periodRangeLabel }}</span>

            @if ($this->period === 'custom')
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
            @foreach ($statCards as $card)
                <article class="rshd-stat-card rshd-stat-card--{{ $card['tone'] }}">
                    <div class="rshd-stat-card__icon">
                        @include('filament.pages.partials.icons.'.$card['icon'])
                    </div>
                    <div class="rshd-stat-card__body">
                        <div class="rshd-stat-card__value">{{ $card['value'] }}</div>
                        <div class="rshd-stat-card__label">{{ $card['label'] }}</div>
                        <div class="rshd-stat-card__unit">{{ $card['unit'] }}</div>
                    </div>
                </article>
            @endforeach
        </section>

        <section class="rshd-accounting-main-grid">
            <article class="rshd-panel rshd-panel--chart">
                <div class="rshd-panel__header rshd-panel__header--row">
                    <h2>الإيرادات والمصاريف خلال الفترة</h2>
                    <span class="rshd-link-muted">{{ $periodRangeLabel }}</span>
                </div>
                <div class="rshd-panel__body">
                    <div class="rshd-chart-legend">
                        <span><i class="rshd-dot rshd-dot--gold"></i> الإيرادات</span>
                        <span><i class="rshd-dot rshd-dot--danger"></i> المصاريف</span>
                    </div>
                    <div class="rshd-simple-chart">
                        @if (! $chartHasValues)
                            <div class="rshd-empty rshd-chart-empty-state">
                                لا توجد إيرادات أو مصاريف في الفترة المحددة.
                                @if ($this->period === 'today')
                                    <span class="rshd-chart-empty-state__hint">جرّب «هذا الشهر» لعرض البيانات السابقة.</span>
                                @endif
                            </div>
                        @else
                        @foreach ($data['chartLabels'] as $index => $label)
                            @php
                                $revenueAmount = (float) ($data['chartRevenue'][$index] ?? 0);
                                $expenseAmount = (float) ($data['chartExpenses'][$index] ?? 0);
                                $revenueHeight = $revenueAmount > 0 ? max(6, ($revenueAmount / $maxChart) * 100) : 0;
                                $expenseHeight = $expenseAmount > 0 ? max(6, ($expenseAmount / $maxChart) * 100) : 0;
                            @endphp
                            <div class="rshd-simple-chart__group">
                                <div class="rshd-simple-chart__bars">
                                    <div
                                        class="rshd-simple-chart__bar rshd-simple-chart__bar--revenue"
                                        style="height: {{ $revenueHeight }}%"
                                        title="إيراد: {{ $this->formatMoney($revenueAmount) }}"
                                    ></div>
                                    <div
                                        class="rshd-simple-chart__bar rshd-simple-chart__bar--expense"
                                        style="height: {{ $expenseHeight }}%"
                                        title="مصروف: {{ $this->formatMoney($expenseAmount) }}"
                                    ></div>
                                </div>
                                <span class="rshd-simple-chart__label">{{ $label }}</span>
                            </div>
                        @endforeach
                        @endif
                    </div>
                </div>
            </article>

            <article class="rshd-panel">
                <div class="rshd-panel__header rshd-panel__header--row">
                    <h2>آخر عمليات التفعيل (الإيرادات)</h2>
                    <span class="rshd-link-muted">{{ $periodRangeLabel }}</span>
                </div>
                <div class="rshd-panel__body rshd-panel__body--table">
                    <div class="rshd-table-wrap">
                        <table class="rshd-table">
                            <thead>
                                <tr>
                                    <th>الطالب</th>
                                    <th>المادة</th>
                                    <th>السعر</th>
                                    <th>تاريخ التفعيل</th>
                                    <th>تم بواسطة</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse ($data['latestRevenues'] as $row)
                                    <tr>
                                        <td>{{ $row->student?->name ?? '—' }}</td>
                                        <td>{{ $row->subject?->title ?? '—' }}</td>
                                        <td>{{ $this->formatMoney($row->sale_price) }}</td>
                                        <td>{{ optional($row->paid_at ?? $row->activated_at ?? $row->created_at)?->format('Y-m-d H:i') ?? '—' }}</td>
                                        <td>{{ $row->activatedBy?->name ?? '—' }}</td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="5" class="rshd-empty">لا توجد عمليات تفعيل في الفترة المحددة.</td>
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
                <div class="rshd-panel__header rshd-panel__header--row">
                    <h2>آخر المصاريف</h2>
                    <span class="rshd-link-muted">{{ $periodRangeLabel }}</span>
                </div>
                <div class="rshd-panel__body rshd-panel__body--table">
                    <div class="rshd-table-wrap">
                        <table class="rshd-table">
                            <thead>
                                <tr>
                                    <th>العنوان</th>
                                    <th>المبلغ</th>
                                    <th>التصنيف</th>
                                    <th>التاريخ</th>
                                    <th>الملاحظة</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse ($data['latestExpenses'] as $expense)
                                    <tr>
                                        <td>{{ $expense->title }}</td>
                                        <td>{{ $this->formatMoney($expense->amount) }}</td>
                                        <td>{{ $expense->category ?? '—' }}</td>
                                        <td>{{ optional($expense->expense_date)?->format('Y-m-d') ?? '—' }}</td>
                                        <td>{{ $expense->description ?: '—' }}</td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="5" class="rshd-empty">لا توجد مصاريف في الفترة المحددة.</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
                <div class="rshd-panel__footer rshd-panel__footer--danger">
                    إجمالي المصاريف في الفترة: {{ $this->formatMoney($data['totalExpenses']) }}
                </div>
            </article>

            <article class="rshd-panel rshd-no-print">
                <div class="rshd-panel__header">
                    <h2>إجراءات سريعة</h2>
                </div>
                <div class="rshd-panel__body">
                    <div class="rshd-quick-grid rshd-quick-grid--accounting">
                        @foreach ($quickActions as $action)
                            @if (($action['enabled'] ?? true) && ($action['url'] ?? null))
                                <a href="{{ $action['url'] }}" class="rshd-quick-card">
                                    <span class="rshd-quick-card__icon">
                                        @include('filament.pages.partials.icons.'.$action['icon'])
                                    </span>
                                    <span class="rshd-quick-card__label">{{ $action['label'] }}</span>
                                </a>
                            @else
                                <div
                                    class="rshd-quick-card rshd-quick-card--disabled"
                                    title="{{ $action['disabledReason'] ?? 'غير متاح حالياً' }}"
                                >
                                    <span class="rshd-quick-card__icon">
                                        @include('filament.pages.partials.icons.'.$action['icon'])
                                    </span>
                                    <span class="rshd-quick-card__label">{{ $action['label'] }}</span>
                                </div>
                            @endif
                        @endforeach
                    </div>
                    <p class="rshd-accounting-note">
                        إضافة مادة جديدة متاحة فقط للمدرسين من لوحة المدرّس.
                    </p>
                </div>
            </article>
        </section>
        </div>
    </div>
</x-filament-panels::page>
