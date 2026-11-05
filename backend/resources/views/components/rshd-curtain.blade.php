{{--
    The navy curtain behind RSHD's page transitions and first-visit intro.

    Two halves meet across the middle of the screen and part again through
    the middle of the word on it. Each half holds the same centred content
    and shows only its own half, so the word reads whole until they part.

    The script below runs before the rest of the page renders: a page reached
    from the menu, or a first visit to an intro page, opens already covered.
    public/js/rshd-motion.js then plays the rest.
--}}
@props([
    'logo',
    'intro' => false,
    'introTitle' => 'RSHD',
    'introTagline' => '',
])

<div
    id="rshd-curtain"
    class="rshd-curtain"
    aria-hidden="true"
    data-intro="{{ $intro ? '1' : '0' }}"
    data-intro-title="{{ $introTitle }}"
    data-intro-tagline="{{ $introTagline }}"
>
    @foreach (['top', 'bottom'] as $half)
        <div class="rshd-curtain__half rshd-curtain__half--{{ $half }}">
            <div class="rshd-curtain__stage">
                <div class="rshd-curtain__word">
                    <div class="rshd-curtain__above">
                        <img class="rshd-curtain__mark" src="{{ $logo }}" alt="">
                        <p class="rshd-curtain__eyebrow" data-curtain-eyebrow></p>
                    </div>
                    <p class="rshd-curtain__title" data-curtain-title></p>
                    <p class="rshd-curtain__tagline" data-curtain-tagline></p>
                </div>
            </div>
        </div>
    @endforeach
</div>
<script>
    (function () {
        var curtain = document.getElementById('rshd-curtain');
        if (!curtain || window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
            return;
        }

        function fill(role, text) {
            curtain.querySelectorAll('[data-curtain-' + role + ']').forEach(function (el) {
                el.textContent = text || '';
            });
        }

        function cover(classes) {
            classes.forEach(function (name) {
                curtain.classList.add(name);
            });
            document.documentElement.classList.add('rshd-arriving');
        }

        try {
            var nav = JSON.parse(sessionStorage.getItem('rshd-nav') || 'null');
            sessionStorage.removeItem('rshd-nav');
            if (nav && Date.now() - nav.t < 15000) {
                fill('eyebrow', nav.group);
                fill('title', nav.label);
                cover(['is-closed']);
                return;
            }

            if (curtain.dataset.intro === '1' && !sessionStorage.getItem('rshd-intro')) {
                sessionStorage.setItem('rshd-intro', '1');
                fill('title', curtain.dataset.introTitle);
                fill('tagline', curtain.dataset.introTagline);
                cover(['is-closed', 'is-intro']);
            }
        } catch (e) {
            // No session storage: the page opens without the curtain.
        }
    })();
</script>
