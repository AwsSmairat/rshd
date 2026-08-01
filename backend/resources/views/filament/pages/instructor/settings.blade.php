<div class="rshd-instructor-page">
    @include('filament.pages.instructor.partials.page-header', [
        'title' => 'إعدادات الحساب',
        'subtitle' => 'الإشعارات والخصوصية والجلسات',
    ])

    <div class="rshd-quick-links rshd-quick-links--bar">
        <a href="{{ $this->profileUrl() }}">الملف الشخصي</a>
    </div>

    <div class="rshd-settings-layout">
        <nav class="rshd-settings-nav" aria-label="أقسام الإعدادات">
            <h3>الإعدادات</h3>
            <ul>
                @foreach ([
                    'notifications' => 'إعدادات الإشعارات',
                    'display' => 'تفضيلات العرض',
                    'privacy' => 'إعدادات الخصوصية',
                    'security' => 'الأمان والجلسات',
                ] as $key => $label)
                    <li wire:key="settings-section-{{ $key }}">
                        <button
                            type="button"
                            wire:click="$set('section', '{{ $key }}')"
                            @class(['rshd-settings-nav__item', 'is-active' => $section === $key])
                        >
                            <span class="rshd-settings-nav__icon" aria-hidden="true"></span>
                            {{ $label }}
                        </button>
                    </li>
                @endforeach
            </ul>
        </nav>

        <div class="rshd-settings-main">
            <div class="rshd-settings-mobile-nav">
                <label for="settings-section-select">القسم</label>
                <select id="settings-section-select" wire:model.live="section">
                    <option value="notifications">إعدادات الإشعارات</option>
                    <option value="display">تفضيلات العرض</option>
                    <option value="privacy">إعدادات الخصوصية</option>
                    <option value="security">الأمان والجلسات</option>
                </select>
            </div>

            @if ($section === 'notifications' || $section === 'display' || $section === 'privacy')
                <form wire:submit="saveSettings" class="rshd-settings-card">
                    <div class="rshd-settings-card__header">
                        <h2>{{ $this->sectionLabel() }}</h2>
                        @if ($section === 'notifications')
                            <p>تحكم بالإشعارات التي تصلك داخل المنصة وعبر البريد.</p>
                        @elseif ($section === 'display')
                            <p>اضبط المنطقة الزمنية لتجربة لوحة التحكم.</p>
                        @else
                            <p>حدّد ما يمكن للطلاب رؤيته من ملفك.</p>
                        @endif
                    </div>
                    <div class="rshd-settings-card__body">
                        {{ $this->form }}
                    </div>
                    <div class="rshd-settings-actions">
                        <button type="submit" class="rshd-grade-btn">حفظ الإعدادات</button>
                    </div>
                </form>
            @endif

            @if ($section === 'security')
                <article class="rshd-settings-card">
                    <div class="rshd-settings-card__header">
                        <h2>المصادقة الثنائية</h2>
                        <p>طبقة أمان إضافية لحسابك.</p>
                    </div>
                    <div class="rshd-settings-card__body">
                        <p class="rshd-help-text">المصادقة الثنائية غير مفعّلة حالياً على المنصة.</p>
                    </div>
                </article>

                <article class="rshd-settings-card">
                    <div class="rshd-settings-card__header">
                        <h2>الجلسات والأجهزة</h2>
                        <p>الأجهزة التي سجّلت الدخول منها مؤخراً.</p>
                    </div>
                    <div class="rshd-settings-card__body">
                        @php $sessions = $this->sessions(); @endphp
                        @if ($sessions->isEmpty())
                            <div class="rshd-empty">لا توجد جلسات مسجّلة</div>
                        @else
                            <div class="rshd-table-wrap">
                                <table class="rshd-table">
                                    <thead>
                                        <tr>
                                            <th>الجهاز</th>
                                            <th>IP</th>
                                            <th>آخر نشاط</th>
                                            <th>الحالة</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        @foreach ($sessions as $session)
                                            @php $isCurrent = $session->id === $this->currentSessionId(); @endphp
                                            <tr wire:key="session-{{ $session->id }}">
                                                <td>{{ $this->sessionDeviceLabel($session->user_agent ?? null) }}</td>
                                                <td>{{ $session->ip_address ?? '—' }}</td>
                                                <td>{{ \Illuminate\Support\Carbon::createFromTimestamp($session->last_activity)->locale('ar')->diffForHumans() }}</td>
                                                <td>
                                                    @if ($isCurrent)
                                                        <span class="rshd-badge rshd-badge--success">الجلسة الحالية</span>
                                                    @else
                                                        <span class="rshd-badge rshd-badge--muted">نشطة</span>
                                                    @endif
                                                </td>
                                            </tr>
                                        @endforeach
                                    </tbody>
                                </table>
                            </div>
                        @endif
                    </div>
                    <div class="rshd-settings-actions">
                        <button type="button" wire:click="logoutAllDevices" wire:confirm="سيتم تسجيل الخروج من جميع الأجهزة الأخرى. هل تريد المتابعة؟" class="rshd-grade-btn rshd-grade-btn--outline">
                            تسجيل الخروج من جميع الأجهزة
                        </button>
                        <a href="{{ $this->profileUrl() }}#password" class="rshd-link-muted">تغيير كلمة المرور</a>
                    </div>
                </article>
            @endif
        </div>
    </div>
</div>
