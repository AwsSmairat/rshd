<div class="rshd-instructor-page">
    @include('filament.pages.instructor.partials.page-header', [
        'title' => 'الملف الشخصي',
        'subtitle' => 'إدارة معلوماتك وكلمة المرور',
    ])

    <div class="rshd-profile-layout">
        <aside class="rshd-profile-sidebar">
            @include('filament.pages.instructor.partials.user-avatar', [
                'user' => auth()->user(),
                'class' => 'rshd-dash-header__avatar rshd-profile-avatar',
            ])
            <p class="rshd-profile-name">{{ auth()->user()?->name }}</p>
        </aside>

        <div class="rshd-profile-forms">
            <form wire:submit="saveProfile" class="rshd-panel">
                <div class="rshd-panel__header"><h2>المعلومات الشخصية</h2></div>
                <div class="rshd-panel__body">
                    {{ $this->profileForm }}
                </div>
                <div class="rshd-panel__footer">
                    <button type="submit" class="rshd-grade-btn">حفظ التغييرات</button>
                </div>
            </form>

            <form wire:submit="savePassword" class="rshd-panel" id="password">
                <div class="rshd-panel__header"><h2>تغيير كلمة المرور</h2></div>
                <div class="rshd-panel__body">
                    {{ $this->passwordForm }}
                </div>
                <div class="rshd-panel__footer">
                    <button type="submit" class="rshd-grade-btn">تحديث كلمة المرور</button>
                </div>
            </form>
        </div>
    </div>
</div>
