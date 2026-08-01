<div class="rshd-instructor-page" wire:init="loadActivities">
    @include('filament.pages.instructor.partials.page-header', [
        'title' => 'الحضور',
        'subtitle' => 'نشاط مشاهدة الطلاب لمحاضراتك',
    ])

    <div wire:loading.flex wire:target="loadActivities" class="rshd-dashboard-loading">
        <span>جاري تحميل سجل النشاط...</span>
    </div>

    @if ($this->loadError)
        <div class="rshd-alert rshd-alert--danger">{{ $this->loadError }}</div>
    @endif

    <div class="rshd-quick-links rshd-quick-links--bar">
        <a href="{{ $this->studentsUrl() }}">قائمة الطلاب</a>
        <a href="{{ $this->videosUrl() }}">الفيديوهات</a>
        <a href="{{ $this->certificatesUrl() }}">الشهادات</a>
    </div>

    <article class="rshd-panel rshd-panel--page">
        <div class="rshd-panel__header">
            <h2>آخر نشاط للطلاب</h2>
            <span class="rshd-panel__count">{{ $this->activities->count() }} سجل</span>
        </div>
        <div class="rshd-panel__body">
            @if ($this->activities->isEmpty() && ! $this->loadError)
                <div class="rshd-empty">
                    @if ($this->hasVideosButNoActivity() && $this->hasStudentsButNoActivity())
                        يوجد {{ $this->studentCount }} طالب و{{ $this->videoCount }} فيديو، لكن لم تُسجَّل أي مشاهدة بعد.
                        <div class="rshd-quick-links" style="justify-content: center; margin-top: 0.75rem;">
                            <a href="{{ $this->videosUrl() }}">عرض الفيديوهات</a>
                            <a href="{{ $this->studentsUrl() }}">عرض الطلاب</a>
                        </div>
                    @elseif ($this->videoCount === 0)
                        لا توجد فيديوهات في موادك بعد —
                        <a href="{{ $this->videosUrl() }}" class="rshd-link-muted">أضف فيديوهات</a> لبدء تتبع الحضور.
                    @elseif ($this->studentCount === 0)
                        لا يوجد طلاب مسجّلون في موادك —
                        <a href="{{ $this->studentsUrl() }}" class="rshd-link-muted">عرض الطلاب</a>.
                    @else
                        لا يوجد نشاط مشاهدة مسجّل بعد
                    @endif
                </div>
            @else
                <div class="rshd-table-wrap">
                    <table class="rshd-table">
                        <thead>
                            <tr>
                                <th>الطالب</th>
                                <th>المحاضرة</th>
                                <th>المادة</th>
                                <th>التقدم</th>
                                <th>آخر مشاهدة</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($this->activities as $activity)
                                @php
                                    $subjectId = $activity->video?->lesson?->subject_id;
                                    $videoId = $activity->video?->id;
                                @endphp
                                <tr wire:key="activity-{{ $activity->id }}">
                                    <td>
                                        <a href="{{ $this->studentsUrl() }}" class="rshd-link-muted">{{ $activity->student?->name ?? '—' }}</a>
                                    </td>
                                    <td>
                                        @if ($videoId)
                                            <a href="{{ $this->videoEditUrl($videoId) }}" class="rshd-link-muted">{{ $activity->video?->title ?? '—' }}</a>
                                        @else
                                            {{ $activity->video?->title ?? '—' }}
                                        @endif
                                    </td>
                                    <td>
                                        @if ($subjectId)
                                            <a href="{{ $this->subjectEditUrl($subjectId) }}" class="rshd-link-muted">{{ $activity->video?->lesson?->subject?->title ?? '—' }}</a>
                                        @else
                                            {{ $activity->video?->lesson?->subject?->title ?? '—' }}
                                        @endif
                                    </td>
                                    <td>{{ number_format((float) $activity->completion_percentage, 0) }}%</td>
                                    <td>{{ optional($activity->last_watched_at)->locale('ar')->diffForHumans() ?? '—' }}</td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @endif
        </div>
    </article>
</div>
