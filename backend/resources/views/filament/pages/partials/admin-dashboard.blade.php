@php
    /** @var \App\Filament\Pages\Dashboard $this */
    $user = $this->authUser();
    $data = $this->adminData() ?? [
        'stats' => [
            'students' => 0,
            'studentsThisMonth' => 0,
            'instructors' => 0,
            'instructorsThisMonth' => 0,
            'activeSubjects' => 0,
            'activeSubjectsThisMonth' => 0,
            'pendingActivations' => 0,
            'pendingThisMonth' => 0,
            'monthlyRevenue' => 0,
            'netProfit' => 0,
            'revenueChange' => null,
            'netChange' => null,
        ],
        'pendingActivations' => collect(),
        'recentActivities' => collect(),
        'finance' => [
            'revenue' => 0,
            'expenses' => 0,
            'netProfit' => 0,
            'revenueChange' => null,
            'expensesChange' => null,
            'netChange' => null,
            'chartLabels' => [],
            'chartRevenue' => [],
            'chartExpenses' => [],
        ],
        'alerts' => collect(),
        'settings' => [
            'manualActivationRequired' => true,
            'inAppNotificationsEnabled' => true,
        ],
    ];

    $stats = $data['stats'];
    $pending = $data['pendingActivations'];
    $activities = $data['recentActivities'];
    $finance = $data['finance'];
    $alerts = $data['alerts'];
    $dashboardSettings = $data['settings'];
    $quickActions = $this->adminQuickActions();
    $chartMax = max(1, max($finance['chartRevenue'] ?: [0]), max($finance['chartExpenses'] ?: [0]));

    $monthlyCountHint = function (int $count, string $unit): string {
        if ($count === 0) {
            return 'لا '.$unit.' هذا الشهر';
        }

        return number_format($count).' '.$unit.' هذا الشهر';
    };

    $changeLabel = function (?float $change): string {
        if ($change === null) {
            return 'هذا الشهر';
        }

        $arrow = $change >= 0 ? '↑' : '↓';

        return $arrow.' '.number_format(abs($change), 1).'% عن الشهر الماضي';
    };
@endphp

<div class="rshd-admin-dashboard">
    <section class="rshd-dash-header">
        <div class="rshd-dash-header__content">
            <div class="rshd-dash-header__welcome">
                <h1>مرحباً، {{ $user?->name }}</h1>
                <p>لوحة تحكم الإدارة — نظرة عامة على المنصة</p>
            </div>

            <div class="rshd-dash-header__actions">
                <div class="rshd-dash-header__profile">
                    <div class="rshd-dash-header__avatar">{{ $this->adminInitials() }}</div>
                    <div class="rshd-dash-header__meta">
                        <strong>{{ $user?->name }}</strong>
                        <span>مدير النظام</span>
                    </div>
                </div>
            </div>
        </div>
        <div class="rshd-dash-header__ornament" aria-hidden="true"></div>
    </section>

    <section class="rshd-admin-stats-grid">
        <article class="rshd-admin-stat rshd-admin-stat--green">
            <div class="rshd-admin-stat__icon">@include('filament.pages.partials.icons.users')</div>
            <div>
                <div class="rshd-admin-stat__value">{{ number_format($stats['students']) }}</div>
                <div class="rshd-admin-stat__label">عدد الطلاب</div>
                <div class="rshd-admin-stat__hint">{{ $monthlyCountHint((int) $stats['studentsThisMonth'], 'جديد') }} · إجمالي</div>
            </div>
        </article>
        <article class="rshd-admin-stat rshd-admin-stat--purple">
            <div class="rshd-admin-stat__icon">@include('filament.pages.partials.icons.play')</div>
            <div>
                <div class="rshd-admin-stat__value">{{ number_format($stats['instructors']) }}</div>
                <div class="rshd-admin-stat__label">عدد المدرسين</div>
                <div class="rshd-admin-stat__hint">{{ $monthlyCountHint((int) $stats['instructorsThisMonth'], 'جديد') }} · إجمالي</div>
            </div>
        </article>
        <article class="rshd-admin-stat rshd-admin-stat--blue">
            <div class="rshd-admin-stat__icon">@include('filament.pages.partials.icons.book')</div>
            <div>
                <div class="rshd-admin-stat__value">{{ number_format($stats['activeSubjects']) }}</div>
                <div class="rshd-admin-stat__label">المواد المفعّلة</div>
                <div class="rshd-admin-stat__hint">نشطة حالياً · {{ $monthlyCountHint((int) $stats['activeSubjectsThisMonth'], 'مادة') }}</div>
            </div>
        </article>
        <article class="rshd-admin-stat rshd-admin-stat--orange">
            <div class="rshd-admin-stat__icon">@include('filament.pages.partials.icons.clipboard')</div>
            <div>
                <div class="rshd-admin-stat__value">{{ number_format($stats['pendingActivations']) }}</div>
                <div class="rshd-admin-stat__label">طلبات التفعيل</div>
                <div class="rshd-admin-stat__hint">{{ (int) $stats['pendingThisMonth'] }} هذا الشهر</div>
            </div>
        </article>
        <article class="rshd-admin-stat rshd-admin-stat--gold">
            <div class="rshd-admin-stat__icon">@include('filament.pages.partials.icons.bolt')</div>
            <div>
                <div class="rshd-admin-stat__value">{{ $this->formatMoney($stats['monthlyRevenue']) }}</div>
                <div class="rshd-admin-stat__label">إيرادات الشهر</div>
                <div class="rshd-admin-stat__hint">{{ $changeLabel($stats['revenueChange'] ?? null) }}</div>
            </div>
        </article>
        <article class="rshd-admin-stat rshd-admin-stat--success">
            <div class="rshd-admin-stat__icon">@include('filament.pages.partials.icons.quiz')</div>
            <div>
                <div class="rshd-admin-stat__value">{{ $this->formatMoney($stats['netProfit']) }}</div>
                <div class="rshd-admin-stat__label">صافي الربح</div>
                <div class="rshd-admin-stat__hint">{{ $changeLabel($stats['netChange'] ?? null) }}</div>
            </div>
        </article>
    </section>

    <section class="rshd-admin-mid-grid">
        <article class="rshd-panel">
            <div class="rshd-panel__header rshd-panel__header--row">
                <div>
                    <h2>طلبات التفعيل بانتظار الموافقة</h2>
                    @if (! ($dashboardSettings['manualActivationRequired'] ?? true))
                        <p class="rshd-panel-note">التفعيل التلقائي مفعّل — الطلبات المعلّقة تظهر نادراً.</p>
                    @endif
                </div>
                <a href="{{ $this->enrollmentsIndexUrl() }}" class="rshd-link-muted">عرض جميع الطلبات</a>
            </div>
            <div class="rshd-panel__body rshd-panel__body--table">
                <div class="rshd-table-wrap">
                    <table class="rshd-table">
                        <thead>
                            <tr>
                                <th>الطالب</th>
                                <th>المادة</th>
                                <th>السعر</th>
                                <th>الحالة</th>
                                <th>الإجراء</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse ($pending as $row)
                                <tr>
                                    <td>
                                        <div class="rshd-user-cell">
                                            <span class="rshd-user-cell__avatar">{{ mb_substr($row->student?->name ?? 'ط', 0, 1) }}</span>
                                            <span>{{ $row->student?->name ?? '—' }}</span>
                                        </div>
                                    </td>
                                    <td>{{ $row->subject?->title ?? '—' }}</td>
                                    <td>{{ $this->formatMoney($row->sale_price ?? $row->subject?->price) }}</td>
                                    <td><span class="rshd-badge rshd-badge--warning">بانتظار الموافقة</span></td>
                                    <td>
                                        <div class="rshd-row-actions">
                                            <button
                                                type="button"
                                                class="rshd-btn rshd-btn--gold"
                                                wire:click="activateEnrollment({{ $row->id }})"
                                                wire:confirm="تفعيل المادة لهذا الطالب؟"
                                            >
                                                تفعيل
                                            </button>
                                            <button
                                                type="button"
                                                class="rshd-btn rshd-btn--ghost"
                                                wire:click="rejectEnrollment({{ $row->id }})"
                                                wire:confirm="رفض طلب التفعيل؟"
                                            >
                                                رفض
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="5" class="rshd-empty">لا توجد طلبات تفعيل حالياً</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </article>

        <article class="rshd-panel">
            <div class="rshd-panel__header">
                <h2>إجراءات سريعة</h2>
            </div>
            <div class="rshd-panel__body">
                <div class="rshd-quick-grid rshd-quick-grid--admin">
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

    <section class="rshd-admin-bottom-grid">
        <article class="rshd-panel">
            <div class="rshd-panel__header">
                <h2>آخر النشاطات</h2>
            </div>
            <div class="rshd-panel__body">
                @forelse ($activities as $activity)
                    <div class="rshd-activity-item">
                        <span class="rshd-activity-dot rshd-activity-dot--{{ $activity['tone'] }}"></span>
                        <div class="rshd-activity-item__body">
                            <div class="rshd-activity-item__title">{{ $activity['title'] }}</div>
                            <div class="rshd-activity-item__time">{{ optional($activity['time'])->diffForHumans() }}</div>
                        </div>
                    </div>
                @empty
                    <div class="rshd-empty">لا توجد نشاطات حديثة</div>
                @endforelse
            </div>
        </article>

        <article class="rshd-panel">
            <div class="rshd-panel__header rshd-panel__header--row">
                <h2>ملخص مالي سريع</h2>
                <a href="{{ $this->accountingSummaryUrl() }}" class="rshd-link-muted">عرض التقرير المالي</a>
            </div>
            <div class="rshd-panel__body">
                <div class="rshd-finance-kpis">
                    <div>
                        <span>الإيرادات</span>
                        <strong>{{ $this->formatMoney($finance['revenue']) }}</strong>
                        <small>{{ $changeLabel($finance['revenueChange'] ?? null) }}</small>
                    </div>
                    <div>
                        <span>المصاريف</span>
                        <strong class="is-danger">{{ $this->formatMoney($finance['expenses']) }}</strong>
                        <small>{{ $changeLabel($finance['expensesChange'] ?? null) }}</small>
                    </div>
                    <div>
                        <span>صافي الربح</span>
                        <strong class="is-success">{{ $this->formatMoney($finance['netProfit']) }}</strong>
                        <small>{{ $changeLabel($finance['netChange'] ?? null) }}</small>
                    </div>
                </div>

                <div class="rshd-mini-chart">
                    @foreach ($finance['chartLabels'] as $index => $label)
                        <div class="rshd-mini-chart__group">
                            <div class="rshd-mini-chart__bars">
                                <div
                                    class="rshd-mini-chart__bar rshd-mini-chart__bar--revenue"
                                    style="height: {{ (($finance['chartRevenue'][$index] ?? 0) / $chartMax) * 100 }}%"
                                ></div>
                                <div
                                    class="rshd-mini-chart__bar rshd-mini-chart__bar--expense"
                                    style="height: {{ (($finance['chartExpenses'][$index] ?? 0) / $chartMax) * 100 }}%"
                                ></div>
                            </div>
                            <span>{{ $label }}</span>
                        </div>
                    @endforeach
                </div>
            </div>
        </article>

        <article class="rshd-panel">
            <div class="rshd-panel__header">
                <h2>تنبيهات النظام</h2>
            </div>
            <div class="rshd-panel__body">
                @forelse ($alerts as $alert)
                    @php
                        $alertUrl = match ($alert['key'] ?? '') {
                            'submissions' => $this->submissionsIndexUrl(),
                            'activations' => $this->enrollmentsIndexUrl(),
                            'devices' => \App\Filament\Resources\StudentDeviceResource::getUrl('index'),
                            'unverified' => \App\Filament\Resources\StudentResource::getUrl('index'),
                            default => null,
                        };
                    @endphp
                    <a
                        @if ($alertUrl) href="{{ $alertUrl }}" @endif
                        class="rshd-alert-item rshd-alert-item--{{ $alert['tone'] }}"
                        @if (! $alertUrl) style="cursor:default" @endif
                    >
                        <div class="rshd-alert-item__count">{{ number_format($alert['count']) }}</div>
                        <div class="rshd-alert-item__title">{{ $alert['title'] }}</div>
                    </a>
                @empty
                    <div class="rshd-empty">لا توجد تنبيهات حالياً</div>
                @endforelse
            </div>
        </article>
    </section>
</div>
