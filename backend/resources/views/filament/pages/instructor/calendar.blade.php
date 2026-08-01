<div class="rshd-instructor-page" wire:init="loadCalendar">
    @include('filament.pages.instructor.partials.page-header', [
        'title' => 'التقويم',
        'subtitle' => 'مواعيد الواجبات والاختبارات خلال الأسبوع',
    ])

    @if ($this->loadError)
        <div class="rshd-alert rshd-alert--danger">{{ $this->loadError }}</div>
    @endif

    @php
        $days = $this->calendarDays();
        $selected = $this->selectedDay();
    @endphp

    <div wire:loading.flex wire:target="loadCalendar,selectDay" class="rshd-dashboard-loading">
        <span>جاري تحميل التقويم...</span>
    </div>

    @if ($days->isEmpty() && $this->loadError)
        <div class="rshd-empty-state">
            <p>تعذر عرض التقويم.</p>
        </div>
    @else
        <div class="rshd-calendar-week rshd-calendar-week--interactive">
            @foreach ($days as $day)
                <button
                    type="button"
                    wire:click="selectDay('{{ $day['date_key'] }}')"
                    wire:key="calendar-day-{{ $day['date_key'] }}"
                    @class([
                        'rshd-calendar-day',
                        'rshd-calendar-day--today' => $day['is_today'],
                        'rshd-calendar-day--selected' => $selected && $selected['date_key'] === $day['date_key'],
                    ])
                    aria-pressed="{{ $selected && $selected['date_key'] === $day['date_key'] ? 'true' : 'false' }}"
                    aria-label="{{ $day['day_name'] }} {{ $day['label'] }}"
                >
                    <header>
                        <span class="rshd-calendar-day__name">{{ $day['day_name'] }}</span>
                        <span class="rshd-calendar-day__date">{{ $day['label'] }}</span>
                    </header>
                    @if (($day['events_count'] ?? 0) > 0)
                        <span class="rshd-calendar-day__badge">{{ $day['events_count'] }}</span>
                    @else
                        <span class="rshd-calendar-day__empty">—</span>
                    @endif
                </button>
            @endforeach
        </div>

        <article class="rshd-panel rshd-calendar-detail">
            @if ($selected)
                <div class="rshd-panel__header">
                    <h2>جدول {{ $selected['day_name'] }} {{ $selected['label'] }}</h2>
                    <span class="rshd-panel__count">{{ count($selected['events']) }} عنصر</span>
                </div>
                <div class="rshd-panel__body">
                    @if (empty($selected['events']))
                        <div class="rshd-empty">لا توجد مواعيد أو أنشطة في هذا اليوم</div>
                    @else
                        <div class="rshd-calendar-events-list">
                            @foreach ($selected['events'] as $event)
                                <div @class(['rshd-calendar-event-row', 'rshd-calendar-event-row--'.$event['type']])>
                                    <div class="rshd-calendar-event-row__meta">
                                        <span class="rshd-calendar-event-row__type">{{ $event['type_label'] }}</span>
                                        @if ($event['time'])
                                            <span class="rshd-calendar-event-row__time">{{ $event['time'] }}</span>
                                        @endif
                                    </div>
                                    <div class="rshd-calendar-event-row__body">
                                        <strong>{{ $event['title'] }}</strong>
                                        @if ($event['subject_title'])
                                            <span class="rshd-calendar-event-row__subject">{{ $event['subject_title'] }}</span>
                                        @endif
                                    </div>
                                    @if ($event['url'])
                                        <a href="{{ $event['url'] }}" class="rshd-calendar-event-row__link">عرض</a>
                                    @endif
                                </div>
                            @endforeach
                        </div>
                    @endif
                </div>
            @else
                <div class="rshd-panel__body">
                    <div class="rshd-empty">اختر يوماً لعرض مواعيدك</div>
                </div>
            @endif
        </article>
    @endif
</div>
