<div class="rshd-instructor-page" wire:init="loadStudents">
    @include('filament.pages.instructor.partials.page-header', [
        'title' => 'طلابي',
        'subtitle' => 'الطلاب المسجّلون في موادك فقط',
    ])

    <div wire:loading.flex wire:target="loadStudents" class="rshd-dashboard-loading">
        <span>جاري تحميل قائمة الطلاب...</span>
    </div>

    @if ($this->loadError)
        <div class="rshd-alert rshd-alert--danger">{{ $this->loadError }}</div>
    @endif

    <article class="rshd-panel rshd-panel--page">
        <div class="rshd-panel__header">
            <h2>قائمة الطلاب</h2>
            <span class="rshd-panel__count">
                {{ $this->studentRows->count() }} طالب
                @if ($this->enrollmentCount() > 0)
                    · {{ $this->enrollmentCount() }} تسجيل
                @endif
            </span>
        </div>
        <div class="rshd-panel__body">
            @if ($this->studentRows->isEmpty() && ! $this->loadError)
                <div class="rshd-empty">لا يوجد طلاب مسجّلون في موادك حالياً</div>
            @else
                <div class="rshd-table-wrap">
                    <table class="rshd-table">
                        <thead>
                            <tr>
                                <th>الطالب</th>
                                <th>البريد</th>
                                <th>الهاتف</th>
                                <th>المواد</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($this->studentRows as $row)
                                @php $student = $row['student']; @endphp
                                <tr wire:key="student-{{ $student->id }}-{{ $student->updated_at?->timestamp }}">
                                    <td>{{ $student->name }}</td>
                                    <td>{{ $student->email ?? '—' }}</td>
                                    <td>{{ $student->phone ?? '—' }}</td>
                                    <td>{{ implode('، ', $row['subject_titles']) }}</td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @endif
        </div>
    </article>
</div>
