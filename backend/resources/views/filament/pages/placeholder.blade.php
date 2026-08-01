@php
    $content = method_exists($this, 'placeholderContent')
        ? $this->placeholderContent()
        : ['title' => 'قريباً', 'message' => 'هذه الصفحة قيد التطوير.'];
@endphp

<x-filament-panels::page>
    <div class="rshd-placeholder-card">
        <div class="rshd-placeholder-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6l4 2" />
                <circle cx="12" cy="12" r="9" />
            </svg>
        </div>
        <h2>{{ $content['title'] }}</h2>
        <p>{{ $content['message'] }}</p>
    </div>
</x-filament-panels::page>
