@php
    /** @var \App\Models\User|null $user */
    $user = $user ?? auth()->user();
    $avatarUrl = $user?->getFilamentAvatarUrl();
    $initials = $user?->initials() ?? 'م';
    $avatarClass = $class ?? 'rshd-dash-header__avatar';
    $avatarTag = $tag ?? 'div';
@endphp

<{{ $avatarTag }}
    @if ($avatarTag === 'a')
        href="{{ $href ?? '#' }}"
    @endif
    @if (! empty($title))
        title="{{ $title }}"
    @endif
    class="{{ $avatarClass }}"
>
    @if ($avatarUrl)
        <img src="{{ $avatarUrl }}" alt="{{ $user?->name ?? 'الصورة الشخصية' }}">
    @else
        {{ $initials }}
    @endif
</{{ $avatarTag }}>
