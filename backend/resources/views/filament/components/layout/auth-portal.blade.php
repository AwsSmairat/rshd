@php
    $livewire ??= null;
@endphp

<x-filament-panels::layout.base :livewire="$livewire">
    <x-auth-portal-shell>
        {{ $slot }}
    </x-auth-portal-shell>
</x-filament-panels::layout.base>
