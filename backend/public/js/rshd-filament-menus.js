(function () {
    const bound = new WeakSet();

    function bindTriggers(root) {
        (root || document).querySelectorAll('.fi-dropdown-trigger').forEach(function (el) {
            // The top navigation menus must hear the click outside, so that
            // opening one closes the one already open.
            if (bound.has(el) || el.closest('.fi-topbar')) {
                return;
            }

            bound.add(el);
            el.addEventListener('click', function (event) {
                event.stopPropagation();
            });
        });
    }

    // With the menu along the top, the drawer is only for narrow screens.
    // Filament remembers it as open from wide screens, so a phone would
    // open every page behind it; start closed instead.
    function closeDrawerOnNarrowScreens() {
        if (!document.querySelector('.fi-topbar-with-navigation')) {
            return;
        }
        if (window.innerWidth >= 1024) {
            return;
        }
        const sidebar = window.Alpine && window.Alpine.store('sidebar');
        if (sidebar && sidebar.isOpen) {
            sidebar.close();
        }
    }

    function boot() {
        bindTriggers();
        document.addEventListener('alpine:initialized', closeDrawerOnNarrowScreens);
        document.addEventListener('livewire:navigated', closeDrawerOnNarrowScreens);
        // Alpine may have started before this script ran.
        if (window.Alpine && typeof window.Alpine.store === 'function') {
            closeDrawerOnNarrowScreens();
        }
        document.addEventListener('livewire:navigated', function () {
            bindTriggers();
        });
        document.addEventListener('livewire:init', function () {
            if (window.Livewire && typeof window.Livewire.hook === 'function') {
                window.Livewire.hook('morph.updated', function () {
                    bindTriggers();
                });
            }
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', boot);
    } else {
        boot();
    }
})();
