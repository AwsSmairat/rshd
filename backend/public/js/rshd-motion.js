/*
 * RSHD page motion: the curtain between pages, the first-visit intro, and
 * the gentle arrival of a page's content.
 *
 * Leaving: a circle closes in over the page towards the middle of the screen,
 * leaving the curtain with the next page's name.
 * Arriving: the new page opens behind the closed curtain (see
 * components/rshd-curtain.blade.php); a circle then grows out of the middle
 * of the words to reveal it, while the page's blocks rise into place one
 * after another.
 *
 * Timers, never animation events, set every final state, and a page restored
 * from the back/forward cache is uncovered at once.
 */
(function () {
    const STORAGE_KEY = 'rshd-nav';
    const CLOSE_MS = 550;
    const HOLD_MS = 420;
    const OPEN_MS = 1250;
    const INTRO_OPEN_AT_MS = 2300;
    const STUCK_MS = 8000;
    const STAGGER_MS = 70;
    const MAX_STAGGERED = 14;

    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
    const root = document.documentElement;

    // The circle animates a registered CSS property; without @property the
    // curtain fades instead.
    if (!(window.CSS && typeof window.CSS.registerProperty === 'function')) {
        root.classList.add('rshd-no-iris');
    }

    // The blocks of each kind of page that arrive one after another.
    const ENTER_SELECTORS = [
        // Admin panel
        '.fi-header',
        '.fi-main .fi-wi-widget',
        '.fi-main .fi-wi-stats-overview-stat',
        '.fi-main .fi-section',
        '.fi-main .fi-ta-ctn',
        // Login
        '.rshd-auth-portal__top',
        '.rshd-auth-portal__info > *',
        '.rshd-auth-portal__card',
        '.rshd-auth-portal__footer',
        // Home page
        '.site-header',
        '.hero-copy > *',
        '.hero-card',
        '.features .section-heading',
        '.feature-grid > article',
    ].join(',');

    function curtain() {
        return document.getElementById('rshd-curtain');
    }

    function fill(el, role, text) {
        el.querySelectorAll('[data-curtain-' + role + ']').forEach(function (node) {
            node.textContent = text || '';
        });
    }

    function reset() {
        const el = curtain();
        if (el) {
            el.classList.remove('is-closing', 'is-closed', 'is-opening', 'is-intro');
        }
        root.classList.remove('rshd-arriving', 'rshd-leaving');
    }

    // ---- Arrival ----

    function stagger() {
        const blocks = Array.from(document.querySelectorAll(ENTER_SELECTORS))
            .filter(function (node) {
                const box = node.getBoundingClientRect();
                return box.width > 0 && box.top < window.innerHeight * 1.2;
            })
            .slice(0, MAX_STAGGERED);

        blocks.forEach(function (node, index) {
            node.style.setProperty('--rshd-i', String(index));
            node.classList.add('rshd-enter');
        });

        // The entrance leaves a transform behind; take it off once done, as a
        // transform would trap fixed menus and dialogs inside the block.
        window.setTimeout(function () {
            blocks.forEach(function (node) {
                node.classList.remove('rshd-enter');
                node.style.removeProperty('--rshd-i');
            });
        }, 900 + blocks.length * STAGGER_MS + 300);
    }

    // Centre the circle on the middle of the words.
    function centreOnWords(el) {
        const word = el.querySelector('.rshd-curtain__half--top .rshd-curtain__title');
        const box = word && word.getBoundingClientRect();
        if (!box || !box.width) {
            el.style.removeProperty('--rshd-cx');
            el.style.removeProperty('--rshd-cy');
            return;
        }
        el.style.setProperty('--rshd-cx', Math.round(box.left + box.width / 2) + 'px');
        el.style.setProperty('--rshd-cy', Math.round(box.top + box.height / 2) + 'px');
    }

    function open() {
        const el = curtain();
        if (!el || !el.classList.contains('is-closed')) {
            return;
        }
        centreOnWords(el);
        stagger();
        el.classList.add('is-opening');
        el.classList.remove('is-closed');
        root.classList.remove('rshd-arriving');
        window.setTimeout(reset, OPEN_MS + 100);
    }

    function splitLetters(el) {
        el.querySelectorAll('[data-curtain-title]').forEach(function (title) {
            const text = title.textContent;
            // Only Latin words are split: Arabic letters must stay joined.
            if (!/^[\x20-\x7E]+$/.test(text)) {
                return;
            }
            // Separate letter boxes would otherwise run right to left.
            title.setAttribute('dir', 'ltr');
            title.textContent = '';
            Array.from(text).forEach(function (letter, index) {
                const span = document.createElement('span');
                span.className = 'rshd-curtain__char';
                span.style.setProperty('--rshd-c', String(index));
                span.textContent = letter;
                title.appendChild(span);
            });
        });
    }

    function arrive() {
        const el = curtain();
        if (!el || !el.classList.contains('is-closed')) {
            return;
        }

        if (!el.classList.contains('is-intro')) {
            window.setTimeout(open, HOLD_MS);
            return;
        }

        // First visit: the mark, the name letter by letter, the tagline, then
        // the screen opens. Any click or key skips straight to the page.
        splitLetters(el);
        const timer = window.setTimeout(open, INTRO_OPEN_AT_MS);
        const skip = function () {
            window.clearTimeout(timer);
            document.removeEventListener('keydown', skip);
            el.removeEventListener('click', skip);
            open();
        };
        document.addEventListener('keydown', skip);
        el.addEventListener('click', skip);
    }

    // ---- Leaving ----

    let openedGroup = '';

    function labelOf(link) {
        if (link.dataset.rshdTitle) {
            return link.dataset.rshdTitle;
        }
        const label = link.querySelector(
            '.fi-topbar-item-label, .fi-dropdown-list-item-label, .fi-sidebar-item-label'
        );
        return (label || link).textContent.replace(/\s+/g, ' ').trim();
    }

    function groupOf(link) {
        if (link.dataset.rshdGroup) {
            return link.dataset.rshdGroup;
        }
        const sidebarGroup = link.closest('.fi-sidebar-group');
        if (sidebarGroup) {
            const label = sidebarGroup.querySelector('.fi-sidebar-group-label');
            return label ? label.textContent.trim() : '';
        }
        return link.closest('.rshd-nav-panel') ? openedGroup : '';
    }

    function isPlainNavigation(event, link) {
        if (event.defaultPrevented || event.button !== 0) {
            return false;
        }
        if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {
            return false;
        }
        if ((link.target && link.target !== '_self') || link.hasAttribute('download')) {
            return false;
        }
        const url = new URL(link.href, window.location.href);
        return url.origin === window.location.origin
            && url.pathname + url.search !== window.location.pathname + window.location.search;
    }

    function onClick(event) {
        if (reduceMotion.matches) {
            return;
        }

        const trigger = event.target.closest('.fi-topbar .fi-dropdown-trigger');
        if (trigger) {
            const label = trigger.querySelector('.fi-topbar-item-label');
            openedGroup = label ? label.textContent.trim() : '';
            return;
        }

        const link = event.target.closest(
            '.fi-topbar a[href], .rshd-nav-panel a[href], .fi-sidebar a.fi-sidebar-item-button[href], a[data-rshd-title]'
        );
        const el = curtain();
        if (!link || !el || !isPlainNavigation(event, link)) {
            return;
        }

        event.preventDefault();
        const label = labelOf(link);
        const group = groupOf(link);

        try {
            window.sessionStorage.setItem(
                STORAGE_KEY,
                JSON.stringify({ label: label, group: group, t: Date.now() })
            );
        } catch (e) {
            // Private mode: the next page simply opens without the curtain.
        }

        fill(el, 'eyebrow', group);
        fill(el, 'title', label);
        fill(el, 'tagline', '');
        el.classList.remove('is-opening', 'is-closed', 'is-intro');
        // The words are centred on the screen, so the circle closes there.
        el.style.removeProperty('--rshd-cx');
        el.style.removeProperty('--rshd-cy');
        el.classList.add('is-closing');
        root.classList.add('rshd-leaving');

        window.setTimeout(function () {
            window.location.assign(link.href);
        }, CLOSE_MS);

        // If the page never changes (the browser kept us here), uncover.
        window.setTimeout(reset, STUCK_MS);
    }

    document.addEventListener('click', onClick, true);

    window.addEventListener('pageshow', function (event) {
        if (event.persisted) {
            reset();
        }
    });

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', arrive);
    } else {
        arrive();
    }
})();
