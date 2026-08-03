@php
    /** @var \App\Filament\Pages\Dashboard $this */
    $data = $this->instructorData();
    $user = $this->authUser();

    $defaults = [
        'stats' => [
            'subjects' => 0,
            'lessons' => 0,
            'students' => 0,
            'pending_submissions' => 0,
            'active_quizzes' => 0,
        ],
        'pendingSubmissions' => collect(),
        'recentActivities' => collect(),
        'subjects' => collect(),
        'studentOverview' => ['total' => 0, 'active' => 0, 'avg_progress' => 0, 'success_rate' => 0],
        'coursePerformance' => ['labels' => [], 'views' => [], 'submissions' => [], 'max_value' => 1],
        'calendarDays' => collect(),
        'alerts' => collect(),
    ];

    $data = array_merge($defaults, $data ?? []);
    $stats = $data['stats'];
    $pending = $data['pendingSubmissions'];
    $activities = $data['recentActivities'];
    $subjects = $data['subjects'];
    $overview = $data['studentOverview'];
    $chart = $data['coursePerformance'];
    $calendarDays = $data['calendarDays'];
    $alerts = $data['alerts'];
    $quickActions = $this->quickActions();
    $dashboardError = $this->instructorDashboardError;
    $statCards = $this->instructorStatCards();
@endphp

<div class="rshd-instructor-dashboard" wire:loading.class="rshd-instructor-dashboard--loading">
    <div wire:loading.flex class="rshd-dashboard-loading">
        <span>جاري تحميل لوحة التحكم...</span>
    </div>

    @if ($dashboardError)
        <div class="rshd-alert rshd-alert--danger">{{ $dashboardError }}</div>
    @endif

    {{-- Header --}}
    <section class="rshd-dash-header">
        <div class="rshd-dash-header__content">
            <div class="rshd-dash-header__welcome">
                <h1>مرحباً، {{ $user?->name }}</h1>
                <p>نظرة شاملة على موادك ونشاط طلابك</p>
            </div>

            <div class="rshd-dash-header__actions">
                <a
                    href="{{ $this->instructorNotificationsUrl() }}"
                    class="rshd-icon-btn"
                    title="تسليمات الواجبات"
                    aria-label="تسليمات الواجبات"
                >
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M15 17h5l-1.4-1.4A2 2 0 0 1 18 14.2V11a6 6 0 1 0-12 0v3.2c0 .5-.2 1-.6 1.4L4 17h5m6 0a3 3 0 1 1-6 0" />
                    </svg>
                    @if ($this->instructorPendingCount() > 0)
                        <span class="rshd-icon-btn__badge">{{ $this->instructorPendingCount() }}</span>
                    @endif
                </a>

                @include('filament.pages.instructor.partials.user-avatar', [
                    'user' => $user,
                    'tag' => 'a',
                    'href' => $this->instructorProfileUrl(),
                    'title' => $user?->name,
                ])

                <form method="POST" action="{{ $this->logoutUrl() }}">
                    @csrf
                    <button type="submit" class="rshd-logout-btn">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0 0 13.5 3h-6A2.25 2.25 0 0 0 5.25 5.25v13.5A2.25 2.25 0 0 0 7.5 21h6a2.25 2.25 0 0 0 2.25-2.25V15M12 9l3 3m0 0-3 3m3-3H3" />
                        </svg>
                        <span>تسجيل الخروج</span>
                    </button>
                </form>
            </div>
        </div>
        <div class="rshd-dash-header__ornament" aria-hidden="true"></div>
    </section>

    {{-- Alerts --}}
    @if ($alerts->isNotEmpty())
        <section class="rshd-alerts">
            @foreach ($alerts as $alert)
                <article @class(['rshd-alert', 'rshd-alert--'.$alert['type']])>
                    <div>
                        <strong>{{ $alert['title'] }}</strong>
                        <p>{{ $alert['message'] }}</p>
                    </div>
                    @if ($alert['url'])
                        <a href="{{ $alert['url'] }}">عرض</a>
                    @endif
                </article>
            @endforeach
        </section>
    @endif

    {{-- Stats --}}
    <section class="rshd-stats-grid">
        @foreach ($statCards as $card)
            <a href="{{ $card['url'] }}" class="rshd-stat-card rshd-stat-card--link">
                <div class="rshd-stat-card__icon rshd-stat-card__icon--{{ $card['icon'] }}">
                    @include('filament.pages.partials.icons.'.$card['icon'])
                </div>
                <div class="rshd-stat-card__body">
                    <div class="rshd-stat-card__value">{{ number_format($stats[$card['key']] ?? 0) }}</div>
                    <div class="rshd-stat-card__label">{{ $card['label'] }}</div>
                    <div class="rshd-stat-card__unit">{{ $card['unit'] }}</div>
                </div>
            </a>
        @endforeach
    </section>

    {{-- Quick Actions --}}
    <section class="rshd-section">
        <div class="rshd-section__header">
            <div class="rshd-section__title">
                <span class="rshd-section__bolt">
                    @include('filament.pages.partials.icons.bolt')
                </span>
                <h2>إجراءات سريعة</h2>
            </div>
        </div>

        <div class="rshd-quick-grid rshd-quick-grid--6">
            @foreach ($quickActions as $action)
                @if ($action['enabled'] && ($action['url'] ?? null))
                    <a href="{{ $action['url'] }}" class="rshd-quick-card">
                        <span class="rshd-quick-card__icon">
                            @include('filament.pages.partials.icons.'.$action['icon'])
                        </span>
                        <span class="rshd-quick-card__label">{{ $action['label'] }}</span>
                    </a>
                @else
                    <div class="rshd-quick-card rshd-quick-card--disabled" title="غير متاح">
                        <span class="rshd-quick-card__icon">
                            @include('filament.pages.partials.icons.'.$action['icon'])
                        </span>
                        <span class="rshd-quick-card__label">{{ $action['label'] }}</span>
                    </div>
                @endif
            @endforeach
        </div>
    </section>

    {{-- Chart + Student overview --}}
    <section class="rshd-mid-grid">
        <article class="rshd-panel">
            <div class="rshd-panel__header">
                <h2>أداء الدورات</h2>
                <a href="{{ $this->instructorReportsUrl() }}" class="rshd-panel__link">التقارير</a>
            </div>
            <div class="rshd-panel__body">
                @include('filament.pages.partials.performance-chart', ['chart' => $chart])
            </div>
        </article>

        <article class="rshd-panel">
            <div class="rshd-panel__header">
                <h2>نظرة عامة على الطلاب</h2>
                <a href="{{ $this->instructorStudentsUrl() }}" class="rshd-panel__link">عرض الطلاب</a>
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
    </section>

    {{-- Active courses + Activity + Calendar --}}
    <section class="rshd-bottom-grid rshd-bottom-grid--dashboard">
        <article class="rshd-panel">
            <div class="rshd-panel__header">
                <h2>الدورات النشطة</h2>
                <span class="rshd-panel__count">{{ $subjects->count() }} دورة</span>
            </div>

            <div class="rshd-panel__body rshd-panel__body--scroll">
                @forelse ($subjects as $item)
                    @php $subject = $item['subject']; @endphp
                    <div class="rshd-subject-card">
                        <div class="rshd-subject-card__top">
                            <div class="rshd-subject-card__icon rshd-subject-card__icon--{{ $item['icon'] }}">
                                @include('filament.pages.partials.icons.'.$item['icon'])
                            </div>
                            <div>
                                <h3>
                                    <a href="{{ $this->subjectEditUrl($subject->id) }}">{{ $subject->title }}</a>
                                </h3>
                                <div class="rshd-subject-card__meta">
                                    <span>{{ $item['students_count'] }} طالب</span>
                                    <span>{{ $item['lessons_count'] }} جزء</span>
                                </div>
                            </div>
                        </div>
                        <div class="rshd-subject-card__links">
                            <a href="{{ $this->subjectLessonsUrl($subject->id) }}">الأجزاء</a>
                            <a href="{{ $this->subjectVideosUrl($subject->id) }}">الفيديوهات</a>
                            <a href="{{ $this->subjectAssignmentsUrl($subject->id) }}">الواجبات</a>
                            <a href="{{ $this->subjectQuizzesUrl($subject->id) }}">الاختبارات</a>
                        </div>
                    </div>
                @empty
                    <div class="rshd-empty">لا توجد دورات نشطة بعد</div>
                @endforelse
            </div>

            <div class="rshd-panel__footer">
                <a href="{{ $this->instructorCoursesUrl() }}">عرض جميع الدورات</a>
            </div>
        </article>

        <article class="rshd-panel">
            <div class="rshd-panel__header">
                <h2>آخر الأنشطة</h2>
            </div>

            <div class="rshd-panel__body">
                @forelse ($activities as $activity)
                    <div class="rshd-activity-item">
                        <div class="rshd-activity-item__icon">
                            @include('filament.pages.partials.icons.'.$activity['icon'])
                        </div>
                        <div class="rshd-activity-item__content">
                            <div class="rshd-activity-item__title">{{ $activity['title'] }}</div>
                            <div class="rshd-activity-item__subtitle">{{ $activity['subtitle'] }}</div>
                        </div>
                        <div class="rshd-activity-item__time">
                            {{ optional($activity['time'])->locale('ar')->diffForHumans() }}
                        </div>
                    </div>
                @empty
                    <div class="rshd-empty">لا توجد نشاطات حديثة</div>
                @endforelse
            </div>
        </article>

        <article class="rshd-panel">
            <div class="rshd-panel__header">
                <h2>التقويم</h2>
                <a href="{{ $this->instructorCalendarUrl() }}" class="rshd-panel__link">عرض الكامل</a>
            </div>
            <div class="rshd-panel__body">
                <div class="rshd-calendar-week rshd-calendar-week--compact">
                    @foreach ($calendarDays as $day)
                        <a
                            href="{{ $this->instructorCalendarUrl($day['date_key'] ?? $day['date']->toDateString()) }}"
                            @class(['rshd-calendar-day', 'rshd-calendar-day--today' => $day['is_today']])
                        >
                            <header>
                                <span class="rshd-calendar-day__name">{{ $day['day_name'] }}</span>
                                <span class="rshd-calendar-day__date">{{ $day['date']->format('d') }}</span>
                            </header>
                            @if (($day['events_count'] ?? count($day['events'] ?? [])) > 0)
                                <span class="rshd-calendar-day__badge">{{ $day['events_count'] ?? count($day['events']) }}</span>
                            @endif
                        </a>
                    @endforeach
                </div>
            </div>
        </article>
    </section>

    {{-- Pending grading --}}
    <section class="rshd-panel rshd-panel--wide rshd-panel--standalone">
        <div class="rshd-panel__header">
            <h2>واجبات تحتاج تصحيح</h2>
            @if (($stats['pending_submissions'] ?? 0) > 0)
                <span class="rshd-panel__count">{{ $stats['pending_submissions'] }} تسليم</span>
            @endif
        </div>

        <div class="rshd-panel__body">
            @if ($pending->isEmpty())
                <div class="rshd-empty">لا توجد تسليمات بانتظار التصحيح</div>
            @else
                <div class="rshd-table-wrap">
                    <table class="rshd-table">
                        <thead>
                            <tr>
                                <th>اسم الطالب</th>
                                <th>اسم الواجب</th>
                                <th>المادة</th>
                                <th>تاريخ التسليم</th>
                                <th>إجراء</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($pending as $submission)
                                <tr>
                                    <td>{{ $submission->student?->name ?? '—' }}</td>
                                    <td>{{ $submission->assignment?->title ?? '—' }}</td>
                                    <td>{{ $submission->assignment?->subject?->title ?? '—' }}</td>
                                    <td>
                                        {{ optional($submission->submitted_at)->timezone(config('app.timezone'))->format('Y-m-d H:i') ?? '—' }}
                                    </td>
                                    <td>
                                        <a href="{{ $this->submissionEditUrl($submission->id) }}" class="rshd-grade-btn">
                                            تصحيح
                                        </a>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @endif
        </div>

        <div class="rshd-panel__footer">
            <a href="{{ $this->submissionsIndexUrl() }}">عرض جميع التسليمات</a>
        </div>
    </section>
</div>
