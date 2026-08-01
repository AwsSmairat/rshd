@props(['title', 'subtitle' => null])

<section class="rshd-dash-header rshd-page-header">
    <div class="rshd-dash-header__content">
        <div class="rshd-dash-header__welcome">
            <h1>{{ $title }}</h1>
            @if ($subtitle)
                <p>{{ $subtitle }}</p>
            @endif
        </div>
    </div>
    <div class="rshd-dash-header__ornament" aria-hidden="true"></div>
</section>
