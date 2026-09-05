@php
    $portal = \App\Support\AuthPortal::data();
@endphp

<div class="rshd-auth-portal" dir="{{ $portal['dir'] }}">
    <div class="rshd-auth-portal__top">
        <p class="rshd-auth-portal__slogan">{{ $portal['slogan'] }}</p>
    </div>

    <div class="rshd-auth-portal__grid">
        <section class="rshd-auth-portal__info">
            <div class="rshd-auth-portal__info-icon" aria-hidden="true">
                <img src="{{ asset('images/auth-graduation-cap.png') }}?v=1" alt="">
            </div>
            <h1>{{ $portal['portalTitle'] }}</h1>
            <p class="rshd-auth-portal__lead">{{ $portal['portalSubtitle'] }}</p>

            <article class="rshd-auth-portal__notice">
                <div class="rshd-auth-portal__notice-icon" aria-hidden="true">
                    <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="1.7">
                        <path stroke-linecap="round" d="M16 21v-2a4 4 0 0 0-4-4H7a4 4 0 0 0-4 4v2"/>
                        <circle cx="9.5" cy="7" r="3.2"/>
                        <path stroke-linecap="round" d="M19 8v6M16 11h6"/>
                    </svg>
                </div>
                <div>
                    <strong>{{ $portal['newTeacherTitle'] }}</strong>
                    <span>{{ $portal['newTeacherBody'] }}</span>
                </div>
            </article>

            <div class="rshd-auth-portal__contacts">
                <a class="rshd-auth-contact rshd-auth-contact--whatsapp" href="{{ $portal['phoneHref'] }}" target="_blank" rel="noopener noreferrer">
                    <span class="rshd-auth-contact__icon" aria-hidden="true">
                        <svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor">
                            <path d="M12.04 2C6.5 2 2 6.37 2 11.76c0 1.72.46 3.4 1.34 4.88L2 22l5.53-1.44A10.2 10.2 0 0 0 12.04 21.5C17.58 21.5 22 17.13 22 11.74 22 6.37 17.58 2 12.04 2Zm5.88 14.2c-.24.68-1.4 1.3-1.94 1.34-.5.04-1.12.06-1.8-.11-.42-.1-.95-.3-1.64-.6-2.88-1.25-4.76-4.16-4.9-4.35-.15-.2-1.18-1.57-1.18-3 0-1.42.74-2.12 1-2.4.24-.26.54-.33.72-.33h.52c.16 0 .38-.06.6.46.24.54.8 1.96.86 2.1.08.14.12.3.02.48-.1.2-.14.3-.28.46-.14.16-.3.36-.42.48-.14.14-.28.28-.12.54.16.26.7 1.15 1.5 1.86 1.04.92 1.9 1.2 2.18 1.34.26.12.42.1.58-.06.16-.16.7-.82.88-1.1.18-.28.36-.22.6-.12.26.08 1.64.77 1.92.92.28.14.46.22.52.34.08.14.08.78-.16 1.46Z"/>
                        </svg>
                    </span>
                    <span>
                        <strong>{{ $portal['whatsappLabel'] }}</strong>
                        <em>{{ $portal['phoneDisplay'] }}</em>
                    </span>
                </a>
                <a class="rshd-auth-contact rshd-auth-contact--email" href="{{ $portal['emailHref'] }}">
                    <span class="rshd-auth-contact__icon" aria-hidden="true">
                        <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="1.7">
                            <rect x="3" y="5" width="18" height="14" rx="2"/>
                            <path d="m4 7 8 6 8-6"/>
                        </svg>
                    </span>
                    <span>
                        <strong>{{ $portal['emailLabel'] }}</strong>
                        <em>{{ $portal['email'] }}</em>
                    </span>
                </a>
            </div>

            <p class="rshd-auth-portal__quote">
                <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true">
                    <path d="M4 19V6a2 2 0 0 1 2-2h5v15H6a2 2 0 0 0-2 2Zm9-15h5a2 2 0 0 1 2 2v13a2 2 0 0 0-2-2h-5V4Z"/>
                </svg>
                <span>{{ $portal['quote'] }}</span>
            </p>
        </section>

        <section class="rshd-auth-portal__card">
            {{ $slot }}
        </section>
    </div>

    <footer class="rshd-auth-portal__footer">
        <div class="rshd-auth-portal__vendor">
            <span>{{ $portal['footerCredit'] }}</span>
            @if ($portal['vendorLogoUrl'])
                <img src="{{ $portal['vendorLogoUrl'] }}" alt="{{ $portal['vendorName'] }}">
            @else
                <strong class="rshd-auth-portal__vendor-mark">{{ $portal['vendorName'] }}</strong>
            @endif
        </div>
        <div class="rshd-auth-portal__social">
            <a href="{{ $portal['vendorInstagramUrl'] }}" target="_blank" rel="noopener noreferrer" aria-label="Instagram {{ $portal['vendorInstagramHandle'] }}">
                <svg viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                    <rect x="3" y="3" width="18" height="18" rx="5"></rect>
                    <circle cx="12" cy="12" r="4"></circle>
                    <circle cx="17.5" cy="6.5" r="1" fill="currentColor" stroke="none"></circle>
                </svg>
                <span>{{ $portal['vendorInstagramHandle'] }}</span>
            </a>
        </div>
        <p>{{ $portal['copyright'] }}</p>
        <p class="rshd-auth-portal__footer-slogan">{{ $portal['footerSlogan'] }}</p>
    </footer>

    <div class="rshd-auth-portal__art" aria-hidden="true">
        <svg viewBox="0 0 280 180" width="280" height="180">
            <g opacity="0.92">
                <rect x="40" y="92" width="78" height="54" rx="4" fill="#1F2937"/>
                <rect x="48" y="84" width="78" height="54" rx="4" fill="#374151"/>
                <rect x="56" y="76" width="78" height="54" rx="4" fill="#111827"/>
                <rect x="62" y="82" width="66" height="6" rx="2" fill="#C4A574"/>
                <path d="M118 58c-2-12 14-22 24-14 8 6 4 16-2 20l-10 7c-8 4-12-2-12-13Z" fill="#111827"/>
                <path d="M128 48c8-2 16 4 14 12" stroke="#C4A574" stroke-width="3" fill="none"/>
                <circle cx="148" cy="44" r="7" fill="#C4A574"/>
            </g>
        </svg>
    </div>
</div>
