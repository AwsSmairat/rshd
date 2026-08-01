<?php

namespace App\Filament\Resources;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Filament\Resources\InstructorResource\Pages;
use App\Models\User;
use App\Services\InstructorInvitationService;
use App\Services\PlatformAuditService;
use App\Services\PlatformSettingsService;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Actions\Action;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

class InstructorResource extends Resource
{
    protected static ?string $model = User::class;

    protected static ?string $slug = 'instructors';

    protected static ?string $navigationIcon = 'heroicon-o-academic-cap';

    protected static ?string $navigationGroup = 'الإدارة';

    protected static ?string $navigationLabel = 'المدرسون';

    protected static ?string $modelLabel = 'مدرس';

    protected static ?string $pluralModelLabel = 'المدرسون';

    protected static ?int $navigationSort = 2;

    public static function canAccess(): bool
    {
        $user = auth()->user();

        if ($user?->isAdmin()) {
            return true;
        }

        return $user?->isInstructor()
            && app(PlatformSettingsService::class)->enabled('instructor_can_view_other_instructors', 'instructors');
    }

    public static function canCreate(): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }

    public static function canEdit($record): bool
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

    public static function shouldRegisterNavigation(): bool
    {
        return static::canAccess();
    }

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()->where('role', UserRole::Instructor);
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
                Forms\Components\Select::make('status')
                    ->label('الحالة')
                    ->options([
                        UserStatus::Active->value => 'نشط',
                        UserStatus::Blocked->value => 'محظور',
                    ])
                    ->default(UserStatus::Active->value)
                    ->required()
                    ->helperText('الحالة «محظور» تمنع المدرس من الدخول إلى لوحة التحكم.'),
            ]);
    }

    public static function table(Table $table): Table
    {
        $settings = app(PlatformSettingsService::class);

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
                Tables\Columns\TextColumn::make('password_set_at')
                    ->label('كلمة المرور')
                    ->badge()
                    ->formatStateUsing(fn ($state): string => $state !== null ? 'تم التعيين' : 'في انتظار التعيين')
                    ->color(fn ($state): string => $state !== null ? 'success' : 'warning')
                    ->placeholder('في انتظار التعيين'),
                Tables\Columns\TextColumn::make('invitation_sent_at')
                    ->label('تاريخ الدعوة')
                    ->dateTime()
                    ->placeholder('لم تُرسل بعد')
                    ->toggleable(),
            ])
            ->actions([
                Action::make('resendInvitation')
                    ->label('إعادة إرسال رابط تعيين كلمة المرور')
                    ->icon('heroicon-o-envelope')
                    ->requiresConfirmation()
                    ->modalDescription(fn (): string => $settings->enabled('instructor_invitation_email_enabled', 'email')
                        ? 'سيتم إنشاء رابط جديد وإرساله إلى بريد المدرس.'
                        : 'سيتم إنشاء رابط جديد. إرسال البريد معطّل حالياً في إعدادات المنصة.')
                    ->visible(fn (User $record): bool => (auth()->user()?->isAdmin() ?? false) && $record->password_set_at === null)
                    ->action(function (User $record) use ($settings): void {
                        app(InstructorInvitationService::class)->resendInvitation($record);

                        app(PlatformAuditService::class)->logAdmin(
                            action: 'instructor.invitation_resent',
                            actor: auth()->user(),
                            description: 'تم إعادة إرسال دعوة تعيين كلمة المرور للمدرس «'.$record->name.'».',
                            model: $record,
                        );

                        if ($settings->enabled('instructor_invitation_email_enabled', 'email')) {
                            Notification::make()
                                ->title('تم إرسال رابط تعيين كلمة المرور')
                                ->success()
                                ->send();

                            return;
                        }

                        Notification::make()
                            ->title('تم إنشاء رابط جديد')
                            ->body('إرسال البريد معطّل في إعدادات المنصة.')
                            ->warning()
                            ->send();
                    }),
                Tables\Actions\EditAction::make()
                    ->visible(fn (): bool => auth()->user()?->isAdmin() ?? false),
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
            'index' => Pages\ListInstructors::route('/'),
            'create' => Pages\CreateInstructor::route('/create'),
            'edit' => Pages\EditInstructor::route('/{record}/edit'),
        ];
    }
}
