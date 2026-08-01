<?php

namespace App\Filament\Pages;

use App\Filament\Concerns\InstructorOnlyPage;
use App\Models\User;
use Filament\Facades\Filament;
use Filament\Forms;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Contracts\Support\Htmlable;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Livewire\Attributes\Url;

class InstructorAccountSettings extends Page implements HasForms
{
    use InstructorOnlyPage;
    use InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-cog-6-tooth';

    protected static ?string $navigationGroup = 'الإعدادات والدعم';

    protected static ?string $navigationLabel = 'الإعدادات';

    protected static ?string $title = 'إعدادات الحساب';

    protected static ?int $navigationSort = 1;

    protected static string $view = 'filament.pages.instructor.settings';

    #[Url]
    public string $section = 'notifications';

    /** @var array<string, mixed>|null */
    public ?array $settingsData = [];

    public function mount(): void
    {
        $this->fillFormFromUser();
    }

    public function getTitle(): string|Htmlable
    {
        return 'إعدادات الحساب';
    }

    public function getHeading(): string|Htmlable
    {
        return '';
    }

    public function updatedSection(): void
    {
        $this->fillFormFromUser();
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Toggle::make('notify_submissions')
                    ->label('إشعارات تسليم الواجبات')
                    ->visible(fn (): bool => $this->section === 'notifications'),
                Forms\Components\Toggle::make('notify_messages')
                    ->label('إشعارات الرسائل')
                    ->visible(fn (): bool => $this->section === 'notifications'),
                Forms\Components\Toggle::make('notify_announcements')
                    ->label('إشعارات الإعلانات')
                    ->visible(fn (): bool => $this->section === 'notifications'),
                Forms\Components\Select::make('theme')
                    ->label('تفضيلات العرض')
                    ->options([
                        'light' => 'فاتح',
                    ])
                    ->default('light')
                    ->disabled()
                    ->helperText('الوضع الداكن قريباً.')
                    ->visible(fn (): bool => $this->section === 'display'),
                Forms\Components\Placeholder::make('language')
                    ->label('اللغة')
                    ->content('العربية')
                    ->visible(fn (): bool => $this->section === 'display'),
                Forms\Components\Select::make('timezone')
                    ->label('المنطقة الزمنية')
                    ->options([
                        'Asia/Amman' => 'عمان (Asia/Amman)',
                        'Asia/Riyadh' => 'الرياض (Asia/Riyadh)',
                        'Asia/Dubai' => 'دبي (Asia/Dubai)',
                        'UTC' => 'UTC',
                    ])
                    ->visible(fn (): bool => $this->section === 'display'),
                Forms\Components\Toggle::make('profile_visible')
                    ->label('إظهار الملف للطلاب')
                    ->helperText('يتحكم بظهور ملفك في واجهة الطالب.')
                    ->visible(fn (): bool => $this->section === 'privacy'),
                Forms\Components\Toggle::make('show_email')
                    ->label('إظهار البريد للطلاب')
                    ->helperText('يُطبَّق عند عرض بيانات المدرّس للطلاب.')
                    ->visible(fn (): bool => $this->section === 'privacy'),
            ])
            ->statePath('settingsData');
    }

    protected function getForms(): array
    {
        return ['form'];
    }

    public function saveSettings(): void
    {
        $user = $this->authUser();

        if ($user === null) {
            return;
        }

        $state = $this->form->getState();
        $keysForSection = match ($this->section) {
            'notifications' => ['notify_submissions', 'notify_messages', 'notify_announcements'],
            'display' => ['theme', 'timezone'],
            'privacy' => ['profile_visible', 'show_email'],
            default => [],
        };

        $patch = array_intersect_key($state, array_flip($keysForSection));
        $preferences = array_merge($user->preferences ?? [], $patch);

        $user->update([
            'preferences' => $preferences,
        ]);

        Notification::make()->title('تم حفظ الإعدادات')->success()->send();
    }

    /**
     * @return Collection<int, object>
     */
    public function sessions(): Collection
    {
        $user = $this->authUser();

        if ($user === null) {
            return collect();
        }

        return collect(
            DB::table('sessions')
                ->where('user_id', $user->id)
                ->orderByDesc('last_activity')
                ->limit(10)
                ->get()
        );
    }

    public function currentSessionId(): string
    {
        return (string) session()->getId();
    }

    public function sessionDeviceLabel(?string $userAgent): string
    {
        $agent = strtolower((string) $userAgent);

        return match (true) {
            str_contains($agent, 'iphone') => 'iPhone',
            str_contains($agent, 'ipad') => 'iPad',
            str_contains($agent, 'android') => 'Android',
            str_contains($agent, 'mac os') => 'Mac',
            str_contains($agent, 'windows') => 'Windows',
            str_contains($agent, 'linux') => 'Linux',
            $userAgent === null || $userAgent === '' => 'جهاز غير معروف',
            default => 'متصفح',
        };
    }

    public function logoutAllDevices(): void
    {
        $user = $this->authUser();

        if ($user === null) {
            return;
        }

        $currentSessionId = session()->getId();

        DB::table('sessions')
            ->where('user_id', $user->id)
            ->when($currentSessionId !== '', fn ($query) => $query->where('id', '!=', $currentSessionId))
            ->delete();

        Notification::make()->title('تم تسجيل الخروج من جميع الأجهزة الأخرى')->success()->send();
    }

    public function logoutUrl(): string
    {
        return Filament::getLogoutUrl();
    }

    public function profileUrl(): string
    {
        return InstructorProfile::getUrl();
    }

    public function sectionLabel(): string
    {
        return match ($this->section) {
            'display' => 'تفضيلات العرض',
            'privacy' => 'إعدادات الخصوصية',
            'security' => 'الأمان والجلسات',
            default => 'إعدادات الإشعارات',
        };
    }

    protected function fillFormFromUser(): void
    {
        $user = $this->authUser();
        $preferences = $user?->preferences ?? [];

        $this->form->fill([
            'notify_submissions' => (bool) ($preferences['notify_submissions'] ?? true),
            'notify_messages' => (bool) ($preferences['notify_messages'] ?? true),
            'notify_announcements' => (bool) ($preferences['notify_announcements'] ?? true),
            'theme' => 'light',
            'timezone' => (string) ($preferences['timezone'] ?? config('app.timezone')),
            'profile_visible' => (bool) ($preferences['profile_visible'] ?? true),
            'show_email' => (bool) ($preferences['show_email'] ?? false),
        ]);
    }

    protected function authUser(): ?User
    {
        /** @var User|null */
        return Auth::user();
    }
}
