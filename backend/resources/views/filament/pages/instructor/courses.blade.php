<div class="rshd-instructor-page" wire:init="loadCourses">
    @include('filament.pages.instructor.partials.page-header', [
        'title' => 'الدورات النشطة',
        'subtitle' => 'موادك التعليمية ونشاط الطلاب',
    ])

    <div wire:loading.flex wire:target="loadCourses" class="rshd-dashboard-loading">
        <span>جاري تحميل الدورات...</span>
    </div>

    @if ($this->loadError)
        <div class="rshd-alert rshd-alert--danger">{{ $this->loadError }}</div>
    @endif

    <section class="rshd-courses-grid">
        @forelse ($this->courses as $item)
            @php $subject = $item['subject']; @endphp
            <article class="rshd-subject-card" wire:key="course-{{ $subject->id }}">
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
            </article>
        @empty
            @if (! $this->loadError)
                <div class="rshd-empty-state rshd-empty-state--wide">
                    <p>لا توجد دورات نشطة. <a href="{{ $this->subjectCreateUrl() }}">أضف مادة جديدة</a></p>
                </div>
            @endif
        @endforelse
    </section>

    @if ($this->courses->isNotEmpty())
        <div class="rshd-panel__footer rshd-panel__footer--standalone">
            <a href="{{ $this->subjectsIndexUrl() }}">عرض جميع المواد ({{ $this->courses->count() }})</a>
        </div>
    @endif
</div>
