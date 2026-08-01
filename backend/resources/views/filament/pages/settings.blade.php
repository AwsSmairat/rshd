@php
    /** @var \App\Filament\Pages\Settings $this */
    $sections = $this->sections();
    $meta = $this->sectionMeta();
    $current = $meta[$section] ?? $meta['platform'];
    $formMap = [
        'platform' => 'platformForm',
        'email' => 'emailForm',
        'social' => 'socialForm',
        'payments' => 'paymentsForm',
        'registration' => 'registrationForm',
        'students' => 'studentsForm',
        'instructors' => 'instructorsForm',
        'notifications' => 'notificationsForm',
        'security' => 'securityForm',
        'backup' => 'backupForm',
        'audit' => 'auditForm',
    ];
    $formProperty = $formMap[$section] ?? 'platformForm';
    $env = $this->environmentStatus();
    $statusRows = $this->systemStatus();
@endphp

<x-filament-panels::page>
    <div class="rshd-platform-settings">
        <section class="rshd-settings-header">
            <div class="rshd-settings-header__top">
                <div class="rshd-settings-header__titles">
                    <nav class="rshd-settings-breadcrumb" aria-label="مسار التنقل">
                        <span>الرئيسية</span>
                        <span class="rshd-settings-breadcrumb__sep">←</span>
                        <span>الإعدادات العامة والتجربة الأساسية</span>
                    </nav>
                    <h1>إعدادات المنصة</h1>
                    <p>إدارة الإعدادات العامة والتقنية لمنصة RSHD</p>
                </div>

                <div class="rshd-settings-header__profile">
                    <div class="rshd-dash-header__avatar">{{ $this->adminInitials() }}</div>
                    <div class="rshd-dash-header__meta">
                        <strong>{{ $this->authUser()?->name }}</strong>
                        <span>مسؤول النظام</span>
                    </div>
                </div>
            </div>
            <div class="rshd-settings-header__wave" aria-hidden="true"></div>
        </section>

        <div class="rshd-settings-layout">
            <div class="rshd-settings-main">
                <div class="rshd-settings-mobile-nav">
                    <label for="rshd-settings-section-select">القسم</label>
                            <select id="rshd-settings-section-select" wire:model.live="section">
                        @foreach ($sections as $key => $label)
                            <option value="{{ $key }}" @selected($section === $key)>{{ $label }}</option>
                        @endforeach
                    </select>
                </div>

                <article class="rshd-settings-card">
                    <header class="rshd-settings-card__header">
                        <div>
                            <h2>{{ $current['title'] }}</h2>
                            <p>{{ $current['subtitle'] }}</p>
                        </div>
                    </header>

                    <div class="rshd-settings-card__body">
                        <form wire:submit="{{ $current['save'] }}">
                            {{ $this->{$formProperty} }}

                            <div class="rshd-settings-actions">
                                <x-filament::button type="submit" color="primary" icon="heroicon-o-check">
                                    {{ $current['button'] }}
                                </x-filament::button>

                                @if ($section === 'backup')
                                    <x-filament::button type="button" color="gray" wire:click="runBackupNow">
                                        إنشاء نسخة احتياطية الآن
                                    </x-filament::button>
                                @endif

                                @if ($section === 'audit')
                                    <x-filament::button type="button" color="gray" wire:click="openAuditLogs">
                                        عرض سجل النشاطات
                                    </x-filament::button>
                                @endif
                            </div>
                        </form>
                    </div>
                </article>

                <div class="rshd-settings-bottom-grid">
                    <article class="rshd-settings-card rshd-settings-card--status">
                        <header class="rshd-settings-card__header">
                            <h2>حالة النظام</h2>
                        </header>
                        <div class="rshd-settings-card__body">
                            <ul class="rshd-status-list">
                                @foreach ($statusRows as $row)
                                    <li>
                                        <span>{{ $row['label'] }}</span>
                                        <span @class([
                                            'rshd-status-pill',
                                            'is-success' => $row['tone'] === 'success',
                                            'is-warning' => $row['tone'] === 'warning',
                                            'is-danger' => $row['tone'] === 'danger',
                                        ])>{{ $row['status'] }}</span>
                                    </li>
                                @endforeach
                            </ul>

                            <div class="rshd-env-grid">
                                <div><span>APP_DEBUG</span><strong>{{ $env['app_debug'] ? 'true' : 'false' }}</strong></div>
                                <div><span>HTTPS</span><strong>{{ $env['https'] ? 'مفعّل' : 'غير مفعّل' }}</strong></div>
                                <div><span>البيئة</span><strong>{{ $env['environment'] }}</strong></div>
                                <div><span>Laravel</span><strong>{{ $env['laravel_version'] }}</strong></div>
                                <div><span>PHP</span><strong>{{ $env['php_version'] }}</strong></div>
                            </div>
                        </div>
                    </article>

                    <article class="rshd-settings-card">
                        <header class="rshd-settings-card__header">
                            <h2>صيانة النظام</h2>
                        </header>
                        <div class="rshd-settings-card__body">
                            <form wire:submit="saveMaintenance">
                                {{ $this->maintenanceForm }}

                                <div class="rshd-settings-actions">
                                    <x-filament::button type="submit" color="primary">
                                        حفظ إعدادات الصيانة
                                    </x-filament::button>
                                </div>
                            </form>
                        </div>
                    </article>
                </div>
            </div>

            <aside class="rshd-settings-nav" aria-label="أقسام الإعدادات">
                <h3>الأقسام</h3>
                <ul>
                    @foreach ($sections as $key => $label)
                        <li>
                            <button
                                type="button"
                                wire:click="setSection('{{ $key }}')"
                                @class(['rshd-settings-nav__item', 'is-active' => $section === $key])
                            >
                                <span class="rshd-settings-nav__icon" aria-hidden="true"></span>
                                <span>{{ $label }}</span>
                            </button>
                        </li>
                    @endforeach
                </ul>
            </aside>
        </div>
    </div>
</x-filament-panels::page>
