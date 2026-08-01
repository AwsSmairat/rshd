<?php

namespace App\Filament\Resources;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Filament\Resources\UserResource\Pages;
use App\Models\User;
use App\Services\PlatformSettingsService;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Validation\Rules\Password;

class UserResource extends Resource
{
    protected static ?string $model = User::class;

    protected static ?string $navigationIcon = 'heroicon-o-shield-check';

    protected static ?string $navigationGroup = 'الإدارة';

    protected static ?string $navigationLabel = 'المسؤولون';

    protected static ?string $modelLabel = 'مسؤول';

    protected static ?string $pluralModelLabel = 'المسؤولون';

    protected static ?int $navigationSort = 1;

    public static function canAccess(): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }

    public static function shouldRegisterNavigation(): bool
    {
        return static::canAccess();
    }

    public static function canCreate(): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }

    public static function canDelete(Model $record): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }

    public static function canDeleteAny(): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()->where('role', UserRole::Admin);
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('name')
                    ->label('الاسم')
                    ->required()
                    ->maxLength(255),
                Forms\Components\TextInput::make('email')
                    ->label('البريد الإلكتروني')
                    ->email()
                    ->required()
                    ->maxLength(255)
                    ->unique(ignoreRecord: true),
                Forms\Components\TextInput::make('phone')
                    ->label('الهاتف')
                    ->tel()
                    ->maxLength(255),
                Forms\Components\Hidden::make('role')
                    ->default(UserRole::Admin->value)
                    ->dehydrated(true),
                Forms\Components\Select::make('status')
                    ->label('الحالة')
                    ->options([
                        UserStatus::Active->value => 'نشط',
                        UserStatus::Blocked->value => 'محظور',
                    ])
                    ->default(UserStatus::Active->value)
                    ->required()
                    ->helperText('الحالة «محظور» تمنع المسؤول من الدخول إلى لوحة التحكم.'),
                Forms\Components\TextInput::make('password')
                    ->label('كلمة المرور')
                    ->password()
                    ->revealable()
                    ->dehydrated(fn (?string $state): bool => filled($state))
                    ->required(fn (string $operation): bool => $operation === 'create')
                    ->rule(static::passwordRule())
                    ->helperText(static::passwordRequirementsHint()),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->label('الاسم')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('email')
                    ->label('البريد الإلكتروني')
                    ->searchable(),
                Tables\Columns\TextColumn::make('phone')
                    ->label('الهاتف')
                    ->toggleable()
                    ->placeholder('—'),
                Tables\Columns\TextColumn::make('status')
                    ->label('الحالة')
                    ->badge()
                    ->formatStateUsing(fn (UserStatus $state): string => match ($state) {
                        UserStatus::Active => 'نشط',
                        UserStatus::Blocked => 'محظور',
                    }),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListUsers::route('/'),
            'create' => Pages\CreateUser::route('/create'),
            'edit' => Pages\EditUser::route('/{record}/edit'),
        ];
    }

    protected static function passwordRule(): Password
    {
        $settings = app(PlatformSettingsService::class);
        $rule = Password::min($settings->integer('password_min_length', 8, 'security'));

        if ($settings->enabled('password_require_uppercase', 'security')) {
            $rule = $rule->mixedCase();
        }

        if ($settings->enabled('password_require_number', 'security')) {
            $rule = $rule->numbers();
        }

        if ($settings->enabled('password_require_special', 'security')) {
            $rule = $rule->symbols();
        }

        return $rule;
    }

    protected static function passwordRequirementsHint(): string
    {
        $settings = app(PlatformSettingsService::class);
        $parts = ['الحد الأدنى '.$settings->integer('password_min_length', 8, 'security').' أحرف'];

        if ($settings->enabled('password_require_uppercase', 'security')) {
            $parts[] = 'حرف كبير';
        }

        if ($settings->enabled('password_require_number', 'security')) {
            $parts[] = 'رقم';
        }

        if ($settings->enabled('password_require_special', 'security')) {
            $parts[] = 'رمز خاص';
        }

        return implode('، ', $parts);
    }
}
