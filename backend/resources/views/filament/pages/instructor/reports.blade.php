@php
    $data = $this->reportPayload;
    $stats = $data['stats'] ?? [];
    $overview = $data['studentOverview'] ?? [];
    $chart = $data['coursePerformance'] ?? ['labels' => [], 'views' => [], 'submissions' => [], 'max_value' => 1];
@endphp

<div class="rshd-instructor-page" wire:init="loadReport">
    @include('filament.pages.instructor.partials.page-header', [
        'title' => 'التقارير والإحصائيات',
        'subtitle' => 'إحصائيات موادك وطلابك',
    ])

    <div wire:loading.flex wire:target="loadReport" class="rshd-dashboard-loading">
        <span>جاري تحميل التقارير...</span>
    </div>

    @if ($this->loadError)
        <div class="rshd-alert rshd-alert--danger">{{ $this->loadError }}</div>
    @elseif (empty($data))
        <div class="rshd-empty-state"><p>لا تتوفر بيانات للعرض.</p></div>
    @else
        <section class="rshd-stats-grid rshd-stats-grid--reports">
            @foreach ($this->statCards() as $card)
                <a href="{{ $card['url'] }}" class="rshd-stat-card rshd-stat-card--compact rshd-stat-card--link">
                    <div class="rshd-stat-card__body">
                        <div class="rshd-stat-card__value">{{ number_format($stats[$card['key']] ?? 0) }}</div>
                        <div class="rshd-stat-card__label">{{ $card['label'] }}</div>
                    </div>
                </a>
            @endforeach
        </section>

        <section class="rshd-mid-grid rshd-mid-grid--page">
            <article class="rshd-panel rshd-panel--page">
                <div class="rshd-panel__header">
                    <h2>نظرة عامة على الطلاب</h2>
                    <a href="{{ $this->studentsUrl() }}" class="rshd-panel__link">عرض الطلاب</a>
                </div>
                <div class="rshd-panel__body">
                    <div class="rshd-student-overview">
                        @foreach ([
                            ['label' => 'إجمالي الطلاب', 'value' => $overview['total'] ?? 0, 'suffix' => ''],
                            ['label' => 'الطلاب النشطون', 'value' => $overview['active'] ?? 0, 'suffix' => ''],
                            ['label' => 'متوسط التقدم', 'value' => $overview['avg_progress'] ?? 0, 'suffix' => '%'],
                            ['label' => 'معدل النجاح', 'value' => $overview['success_rate'] ?? 0, 'suffix' => '%'],
                        ] as $metric)
                            <div class="rshd-student-metric">
                                <div class="rshd-student-metric__ring" style="--progress: {{ min(100, (float) $metric['value']) }}%;">
                                    <span>{{ $metric['value'] }}{{ $metric['suffix'] }}</span>
                                </div>
                                <div class="rshd-student-metric__label">{{ $metric['label'] }}</div>
                            </div>
                        @endforeach
                    </div>
                </div>
            </article>

            <article class="rshd-panel rshd-panel--page">
                <div class="rshd-panel__header"><h2>أداء الدورات (7 أيام)</h2></div>
                <div class="rshd-panel__body">
                    @include('filament.pages.partials.performance-chart', ['chart' => $chart])
                </div>
            </article>
        </section>

        <div class="rshd-quick-links">
            <a href="{{ $this->subjectsUrl() }}">المواد</a>
            <a href="{{ $this->assignmentsUrl() }}">الواجبات</a>
            <a href="{{ $this->submissionsUrl() }}">التسليمات</a>
            <a href="{{ \App\Filament\Pages\InstructorCourses::getUrl() }}">الدورات</a>
        </div>
    @endif
</div>
