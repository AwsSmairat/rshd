<?php

namespace App\Filament\Resources;

use App\Enums\AppNotificationType;
use App\Enums\UserRole;
use App\Filament\Resources\NotificationResource\Pages;
use App\Models\AppNotification;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class NotificationResource extends Resource
{
    protected static ?string $model = AppNotification::class;

    protected static ?string $navigationIcon = 'heroicon-o-bell';

    protected static ?string $navigationGroup = 'التواصل';

    protected static ?string $navigationLabel = 'الإشعارات';

    protected static ?string $modelLabel = 'إشعار';

    protected static ?string $pluralModelLabel = 'الإشعارات';

    protected static ?int $navigationSort = 2;

    public static function canAccess(): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }

    public static function shouldRegisterNavigation(): bool
    {
        return static::canAccess();
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('المستلم والمحتوى')
                    ->schema([
                        Forms\Components\Select::make('user_id')
                            ->label('المستخدم')
                            ->relationship(
                                'user',
                                'name',
                                fn (Builder $query) => $query->orderBy('name'),
                            )
                            ->getOptionLabelFromRecordUsing(
                                fn ($record): string => $record->name.' ('.$record->role?->value.')',
                            )
                            ->searchable(['name', 'email'])
                            ->preload()
                            ->required(),
                        Forms\Components\TextInput::make('title')
                            ->label('العنوان')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\Textarea::make('body')
                            ->label('المحتوى')
                            ->required()
                            ->rows(5)
                            ->columnSpanFull(),
                    ])
                    ->columns(2),
                Forms\Components\Section::make('التصنيف')
                    ->schema([
                        Forms\Components\Select::make('type')
                            ->label('النوع')
                            ->options(AppNotificationType::options())
                            ->default(AppNotificationType::Custom->value)
                            ->required(),
                        Forms\Components\Toggle::make('is_read')
                            ->label('مقروء')
                            ->default(false),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('user.name')
                    ->label('المستخدم')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('user.role')
                    ->label('الدور')
                    ->badge()
                    ->formatStateUsing(fn (UserRole|string|null $state): string => match ($state instanceof UserRole ? $state : UserRole::tryFrom((string) $state)) {
                        UserRole::Admin => 'مدير',
                        UserRole::Instructor => 'مدرس',
                        UserRole::Student => 'طالب',
                        default => (string) $state,
                    })
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('title')
                    ->label('العنوان')
                    ->searchable()
                    ->limit(35),
                Tables\Columns\TextColumn::make('body')
                    ->label('المحتوى')
                    ->limit(40)
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('type')
                    ->label('النوع')
                    ->badge()
                    ->formatStateUsing(fn (?string $state): string => AppNotificationType::labelFor($state))
                    ->color(fn (?string $state): string => match (AppNotificationType::tryFrom((string) $state)) {
                        AppNotificationType::SubjectActivated => 'success',
                        AppNotificationType::GradePublished => 'info',
                        AppNotificationType::Announcement => 'warning',
                        AppNotificationType::ActivationRequest => 'danger',
                        default => 'gray',
                    }),
                Tables\Columns\IconColumn::make('is_read')
                    ->label('مقروء')
                    ->boolean()
                    ->trueIcon('heroicon-o-check-circle')
                    ->falseIcon('heroicon-o-x-circle')
                    ->trueColor('success')
                    ->falseColor('danger'),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('Y-m-d H:i')
                    ->sortable(),
            ])
            ->filters([
                TernaryFilter::make('is_read')
                    ->label('مقروء'),
                SelectFilter::make('type')
                    ->label('النوع')
                    ->options(AppNotificationType::options()),
                SelectFilter::make('user.role')
                    ->label('دور المستخدم')
                    ->options([
                        UserRole::Student->value => 'طالب',
                        UserRole::Instructor->value => 'مدرس',
                        UserRole::Admin->value => 'مدير',
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        $value = $data['value'] ?? null;

                        if ($value === null) {
                            return $query;
                        }

                        return $query->whereHas(
                            'user',
                            fn (Builder $userQuery): Builder => $userQuery->where('role', $value),
                        );
                    }),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->emptyStateHeading('لا توجد إشعارات')
            ->emptyStateDescription('ستظهر هنا الإشعارات المرسلة للمستخدمين، أو أنشئ إشعاراً من زر «إضافة إشعار».');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListNotifications::route('/'),
            'create' => Pages\CreateNotification::route('/create'),
            'edit' => Pages\EditNotification::route('/{record}/edit'),
        ];
    }
}
