@php
    /** @var \App\Filament\Pages\Dashboard $this */
@endphp

<x-filament-panels::page>
    @if ($this->isInstructor())
        @include('filament.pages.partials.instructor-dashboard')
    @elseif ($this->isAdmin())
        @include('filament.pages.partials.admin-dashboard')
    @endif
</x-filament-panels::page>
