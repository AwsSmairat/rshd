@php
    $max = max(1, (int) ($chart['max_value'] ?? 1));
    $labels = $chart['labels'] ?? [];
    $views = $chart['views'] ?? [];
    $submissions = $chart['submissions'] ?? [];
@endphp

<div class="rshd-chart">
    <div class="rshd-chart__legend">
        <span><i class="rshd-chart__dot rshd-chart__dot--gold"></i> مشاهدات الدروس</span>
        <span><i class="rshd-chart__dot rshd-chart__dot--navy"></i> تسليمات الواجبات</span>
    </div>
    <div class="rshd-chart__bars">
        @foreach ($labels as $index => $label)
            @php
                $viewHeight = round(((int) ($views[$index] ?? 0) / $max) * 100);
                $subHeight = round(((int) ($submissions[$index] ?? 0) / $max) * 100);
            @endphp
            <div class="rshd-chart__group">
                <div class="rshd-chart__pair">
                    <div class="rshd-chart__bar rshd-chart__bar--gold" style="height: {{ max(4, $viewHeight) }}%;" title="{{ $views[$index] ?? 0 }} مشاهدة"></div>
                    <div class="rshd-chart__bar rshd-chart__bar--navy" style="height: {{ max(4, $subHeight) }}%;" title="{{ $submissions[$index] ?? 0 }} تسليم"></div>
                </div>
                <span class="rshd-chart__label">{{ $label }}</span>
            </div>
        @endforeach
    </div>
    @if (array_sum($views) === 0 && array_sum($submissions) === 0)
        <p class="rshd-chart__empty">لا يوجد نشاط مسجّل خلال الأسبوع الماضي</p>
    @endif
</div>
