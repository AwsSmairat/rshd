<?php

namespace App\Filament\Pages;

use App\Filament\Concerns\InstructorOnlyPage;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Contracts\Support\Htmlable;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class InstructorProfile extends Page implements HasForms
{
    use InstructorOnlyPage;
    use InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-user-circle';

    protected static ?string $navigationGroup = 'الإعدادات والدعم';

    protected static ?string $navigationLabel = 'الملف الشخصي';

    protected static ?string $title = 'الملف الشخصي';

    protected static ?int $navigationSort = 2;

    protected static string $view = 'filament.pages.instructor.profile';

    /** @var array<string, mixed>|null */
    public ?array $profileData = [];

    /** @var array<string, mixed>|null */
    public ?array $passwordData = [];

    public function mount(): void
    {
        $user = $this->authUser();

        $this->profileForm->fill([
            'name' => $user?->name,
            'email' => $user?->email,
            'phone' => $user?->phone,
            'avatar_path' => $user?->avatar_path,
        ]);

        $this->passwordForm->fill([
            'current_password' => '',
            'password' => '',
            'password_confirmation' => '',
        ]);
    }

    public function getTitle(): string|Htmlable
    {
        return 'الملف الشخصي';
    }

    public function getHeading(): string|Htmlable
    {
        return '';
    }

    public function profileForm(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('المعلومات الشخصية')
                    ->schema([
                        Forms\Components\FileUpload::make('avatar_path')
                            ->label('الصورة الشخصية')
                            ->image()
                            ->avatar()
                            ->directory('instructor-avatars')
                            ->disk('public')
                            ->imageEditor()
                            ->maxSize(2048),
                        Forms\Components\TextInput::make('name')
                            ->label('الاسم الكامل')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\TextInput::make('email')
                            ->label('البريد الإلكتروني')
                            ->email()
                            ->required()
                            ->maxLength(255),
                        Forms\Components\TextInput::make('phone')
                            ->label('رقم الهاتف')
                            ->tel()
                            ->maxLength(30),
                    ])
                    ->columns(2),
            ])
            ->statePath('profileData');
    }

    public function passwordForm(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('تغيير كلمة المرور')
                    ->schema([
                        Forms\Components\TextInput::make('current_password')
                            ->label('كلمة المرور الحالية')
                            ->password()
                            ->revealable()
                            ->requiredWith('password'),
                        Forms\Components\TextInput::make('password')
                            ->label('كلمة المرور الجديدة')
                            ->password()
                            ->revealable()
                            ->rule(Password::defaults()),
                        Forms\Components\TextInput::make('password_confirmation')
                            ->label('تأكيد كلمة المرور')
                            ->password()
                            ->revealable()
                            ->same('password'),
                    ])
                    ->columns(1),
            ])
            ->statePath('passwordData');
    }

    public function saveProfile(): void
    {
        $user = $this->authUser();

        if ($user === null) {
            return;
        }

        $data = $this->profileForm->getState();
        $data['email'] = $data['email'] ?? $user->email;

        $avatarPath = $data['avatar_path'] ?? null;

        if (is_array($avatarPath)) {
            $avatarPath = $avatarPath[0] ?? null;
        }

        $this->validate([
            'profileData.email' => 'required|email|max:255|unique:users,email,'.$user->id,
        ]);

        $user->update([
            'name' => $data['name'],
            'email' => $data['email'],
            'phone' => $data['phone'] ?? null,
            'avatar_path' => $avatarPath,
        ]);

        $user->refresh();
        Auth::setUser($user);

        $this->profileForm->fill([
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'avatar_path' => $user->avatar_path,
        ]);

        Notification::make()->title('تم حفظ الملف الشخصي')->success()->send();
    }

    public function savePassword(): void
    {
        $user = $this->authUser();

        if ($user === null) {
            return;
        }

        $data = $this->passwordForm->getState();

        if (blank($data['password'] ?? null)) {
            Notification::make()->title('أدخل كلمة مرور جديدة')->warning()->send();

            return;
        }

        if (! Hash::check((string) ($data['current_password'] ?? ''), (string) $user->password)) {
            Notification::make()->title('كلمة المرور الحالية غير صحيحة')->danger()->send();

            return;
        }

        $user->update([
            'password' => $data['password'],
            'password_set_at' => now(),
        ]);

        $this->passwordForm->fill([
            'current_password' => '',
            'password' => '',
            'password_confirmation' => '',
        ]);

        Notification::make()->title('تم تحديث كلمة المرور')->success()->send();
    }

    protected function getForms(): array
    {
        return [
            'profileForm',
            'passwordForm',
        ];
    }

    protected function authUser(): ?User
    {
        /** @var User|null */
        return Auth::user();
    }
}
