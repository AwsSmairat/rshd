<div class="rshd-instructor-page" wire:init="loadCandidates">
    @include('filament.pages.instructor.partials.page-header', [
        'title' => 'الشهادات',
        'subtitle' => 'طلابك المؤهلون لشهادات الإتمام (80%+ تقدم)',
    ])

    <div wire:loading.flex wire:target="loadCandidates" class="rshd-dashboard-loading">
        <span>جاري تحميل بيانات الشهادات...</span>
    </div>

    @if ($this->loadError)
        <div class="rshd-alert rshd-alert--danger">{{ $this->loadError }}</div>
    @endif

    <div class="rshd-quick-links rshd-quick-links--bar">
        <a href="{{ $this->studentsUrl() }}">عرض الطلاب</a>
        <a href="{{ $this->attendanceUrl() }}">الحضور</a>
        @if ($this->videoCount > 0)
            <a href="{{ $this->videosUrl() }}">الفيديوهات ({{ $this->videoCount }})</a>
        @endif
    </div>

    <article class="rshd-panel rshd-panel--page">
        <div class="rshd-panel__header">
            <h2>أهلية الشهادات</h2>
            <span class="rshd-panel__count">{{ $this->eligibleCount() }} مؤهل</span>
        </div>
        <div class="rshd-panel__body">
            @if ($this->candidates->isEmpty() && ! $this->loadError)
                <div class="rshd-empty">لا يوجد طلاب مسجّلون في موادك حالياً</div>
            @else
                @if (! $this->hasWatchData() && ! $this->loadError)
                    <div class="rshd-alert rshd-alert--info" style="margin-bottom: 1rem;">
                        التقدم يُحسب من مشاهدة الفيديوهات. لم تُسجَّل مشاهدات بعد —
                        @if ($this->videoCount > 0)
                            <a href="{{ $this->attendanceUrl() }}" class="rshd-link-muted">راجع الحضور</a>
                            أو
                            <a href="{{ $this->videosUrl() }}" class="rshd-link-muted">تحقق من الفيديوهات</a>.
                        @else
                            <a href="{{ $this->videosUrl() }}" class="rshd-link-muted">أضف فيديوهات لموادك</a> لبدء تتبع التقدم.
                        @endif
                    </div>
                @endif

                <div class="rshd-table-wrap">
                    <table class="rshd-table">
                        <thead>
                            <tr>
                                <th>الطالب</th>
                                <th>المادة</th>
                                <th>متوسط التقدم</th>
                                <th>الحالة</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($this->candidates as $row)
                                <tr wire:key="cert-{{ $row['student_id'] }}-{{ $row['subject_id'] }}">
                                    <td>
                                        <a href="{{ $this->studentsUrl() }}" class="rshd-link-muted">{{ $row['student_name'] }}</a>
                                    </td>
                                    <td>
                                        <a href="{{ $this->subjectEditUrl($row['subject_id']) }}" class="rshd-link-muted">{{ $row['subject_title'] }}</a>
                                    </td>
                                    <td>{{ $row['avg_progress'] }}%</td>
                                    <td>
                                        @if ($row['eligible'])
                                            <span class="rshd-badge rshd-badge--success">مؤهل للشهادة</span>
                                        @else
                                            <span class="rshd-badge rshd-badge--muted">قيد التقدم</span>
                                        @endif
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @endif
        </div>
    </article>
</div>
