<div class="rshd-instructor-page">
    @include('filament.pages.instructor.partials.page-header', [
        'title' => $this->pageTitle(),
        'subtitle' => $this->pageDescription(),
    ])

    <div class="rshd-empty-state">
        <div class="rshd-empty-state__icon">
            @include('filament.pages.partials.icons.'.$this->pageIcon())
        </div>
        <h2>{{ $this->pageTitle() }}</h2>
        <p>{{ $this->pageDescription() }}</p>
    </div>
</div>
