(function () {
    const bound = new WeakSet();

    function bindTriggers(root) {
        (root || document).querySelectorAll('.fi-dropdown-trigger').forEach(function (el) {
            if (bound.has(el)) {
                return;
            }

            bound.add(el);
            el.addEventListener('click', function (event) {
                event.stopPropagation();
            });
        });
    }

    function boot() {
        bindTriggers();
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
