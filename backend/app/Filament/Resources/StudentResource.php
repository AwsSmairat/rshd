<?php

namespace App\Filament\Resources;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Filament\Resources\StudentResource\Pages;
use App\Filament\Resources\StudentResource\RelationManagers\DevicesRelationManager;
use App\Models\User;
use App\Services\DeviceService;
use App\Services\PlatformAuditService;
use App\Services\PlatformSettingsService;
use App\Services\StudentSessionService;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Actions\Action;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

class StudentResource extends Resource
{
    protected static ?string $model = User::class;

    protected static ?string $slug = 'students';

    protected static ?string $navigationIcon = 'heroicon-o-user-group';

    protected static ?string $navigationGroup = 'المستخدمون';

    protected static ?string $navigationLabel = 'الطلاب';

    protected static ?string $modelLabel = 'طالب';

    protected static ?string $pluralModelLabel = 'الطلاب';

    protected static ?int $navigationSort = 3;

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
        return parent::getEloquentQuery()
            ->where('role', UserRole::Student)
            ->withCount([
                'studentDevices as active_student_devices_count' => fn (Builder $query) => $query->where('is_active', true),
            ]);
    }

    public static function form(Form $form): Form
    {
        $settings = app(PlatformSettingsService::class);

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
                    ->maxLength(255)
                    ->required($settings->enabled('phone_required', 'registration')),
                Forms\Components\Select::make('status')
                    ->label('الحالة')
                    ->options([
                        UserStatus::Active->value => 'نشط',
                        UserStatus::Blocked->value => 'محظور',
                    ])
                    ->default(UserStatus::Active->value)
                    ->required()
                    ->helperText('الحالة «محظور» تمنع الطالب من الدخول إلى التطبيق.'),
                Forms\Components\Toggle::make('mark_email_verified')
                    ->label('البريد الإلكتروني مؤكد')
                    ->default(true)
                    ->helperText('عطّل هذا الخيار إذا أردت أن يؤكد الطالب بريده بنفسه عبر التطبيق.')
                    ->visible(fn (string $operation): bool => $operation === 'create')
                    ->dehydrated(true),
                Forms\Components\DateTimePicker::make('email_verified_at')
                    ->label('تاريخ تأكيد البريد')
                    ->nullable()
                    ->visible(fn (string $operation): bool => $operation === 'edit')
                    ->helperText('اتركه فارغاً إذا كان البريد غير مؤكد.'),
                Forms\Components\TextInput::make('password')
                    ->label('كلمة المرور')
                    ->password()
                    ->revealable()
                    ->dehydrated(fn (?string $state): bool => filled($state))
                    ->required(fn (string $operation): bool => $operation === 'create')
                    ->rule(static::passwordRule())
                    ->helperText(static::passwordRequirementsHint())
                    ->visible(fn (): bool => auth()->user()?->isAdmin() ?? false),
            ]);
    }

    public static function table(Table $table): Table
    {
        $deviceBindingEnabled = app(PlatformSettingsService::class)->deviceBindingEnabled();

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
                    ->toggleable(),
                Tables\Columns\TextColumn::make('status')
                    ->label('الحالة')
                    ->badge()
                    ->formatStateUsing(fn (UserStatus $state): string => match ($state) {
                        UserStatus::Active => 'نشط',
                        UserStatus::Blocked => 'محظور',
                    }),
                Tables\Columns\TextColumn::make('email_verified_at')
                    ->label('تأكيد البريد')
                    ->dateTime()
                    ->placeholder('غير مؤكد')
                    ->toggleable(),
                Tables\Columns\TextColumn::make('active_student_devices_count')
                    ->label('الأجهزة النشطة')
                    ->sortable()
                    ->placeholder('0')
                    ->visible($deviceBindingEnabled),
            ])
            ->actions([
                Action::make('resetDevices')
                    ->label('إعادة تعيين الجهاز')
                    ->icon('heroicon-o-device-phone-mobile')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->modalHeading('إعادة تعيين أجهزة الطالب')
                    ->modalDescription('سيتم تعطيل جميع الأجهزة المسجلة لهذا الطالب وتسجيل خروجه منها، فيستطيع الدخول من أي جهاز جديد.')
                    ->visible($deviceBindingEnabled)
                    ->action(function (User $record): void {
                        app(DeviceService::class)->resetStudentDevices($record, auth()->user());

                        Notification::make()
                            ->title('تم إعادة تعيين الأجهزة')
                            ->success()
                            ->send();
                    }),
                Action::make('signOutEverywhere')
                    ->label('تسجيل خروج الطالب')
                    ->icon('heroicon-o-arrow-right-on-rectangle')
                    ->color('warning')
                    ->requiresConfirmation()
                    ->modalHeading('تسجيل خروج الطالب من كل الأجهزة')
                    ->modalDescription('سيُطلب من الطالب تسجيل الدخول من جديد على كل أجهزته. تبقى أجهزته المسجّلة كما هي، فيستطيع الدخول من نفس الجهاز.')
                    ->action(function (User $record): void {
                        $ended = app(StudentSessionService::class)->endAll($record);

                        app(PlatformAuditService::class)->logAuth(
                            'session.signed_out_by_admin',
                            auth()->user(),
                            'تم تسجيل خروج الطالب «'.$record->name.'» من كل الأجهزة.',
                            $record,
                        );

                        Notification::make()
                            ->title($ended > 0 ? 'تم تسجيل خروج الطالب من كل الأجهزة' : 'لا توجد جلسات مفتوحة لهذا الطالب')
                            ->success()
                            ->send();
                    }),
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            DevicesRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListStudents::route('/'),
            'create' => Pages\CreateStudent::route('/create'),
            'edit' => Pages\EditStudent::route('/{record}/edit'),
        ];
    }

    protected static function passwordRule(): \Closure
    {
        return app(PlatformSettingsService::class)->passwordStrengthRule();
    }

    protected static function passwordRequirementsHint(): string
    {
        return 'يجب أن تحتوي على: '
            .implode('، ', app(PlatformSettingsService::class)->passwordRequirements());
    }
}
