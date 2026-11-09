<?php

namespace App\Filament\Resources;

use App\Enums\AppNotificationType;
use App\Enums\UserRole;
use App\Filament\Resources\NotificationResource\Pages;
use App\Models\Announcement;
use App\Models\AppNotification;
use App\Models\Assignment;
use App\Models\Lesson;
use App\Models\Quiz;
use App\Models\Subject;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Forms\Get;
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

    public const AUDIENCE_USER = 'user';

    public const AUDIENCE_STUDENTS = 'students';

    public const AUDIENCE_SUBJECT = 'subject';

    public const AUDIENCE_ALL_STUDENTS = 'all_students';

    public static function form(Form $form): Form
    {
        $isCreate = fn (string $operation): bool => $operation === 'create';
        $audienceIs = fn (string $audience) => fn (Get $get, string $operation): bool => $operation !== 'create'
            ? $audience === self::AUDIENCE_USER
            : ($get('audience') ?? self::AUDIENCE_USER) === $audience;
        $typeIn = fn (array $types) => fn (Get $get): bool => in_array($get('type'), $types, true);

        return $form
            ->schema([
                Forms\Components\Section::make('المستلمون')
                    ->schema([
                        Forms\Components\ToggleButtons::make('audience')
                            ->label('إرسال إلى')
                            ->options([
                                self::AUDIENCE_USER => 'مستخدم واحد',
                                self::AUDIENCE_STUDENTS => 'طلاب محددون',
                                self::AUDIENCE_SUBJECT => 'طلاب مادة',
                                self::AUDIENCE_ALL_STUDENTS => 'جميع الطلاب',
                            ])
                            ->default(self::AUDIENCE_USER)
                            ->inline()
                            ->live()
                            ->required()
                            ->dehydrated()
                            ->visible($isCreate)
                            ->columnSpanFull(),
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
                            ->visible($audienceIs(self::AUDIENCE_USER))
                            ->required($audienceIs(self::AUDIENCE_USER)),
                        Forms\Components\Select::make('student_ids')
                            ->label('الطلاب')
                            ->multiple()
                            ->searchable()
                            ->getSearchResultsUsing(fn (string $search): array => User::query()
                                ->where('role', UserRole::Student)
                                ->where(fn (Builder $query) => $query
                                    ->where('name', 'like', '%'.$search.'%')
                                    ->orWhere('email', 'like', '%'.$search.'%'))
                                ->orderBy('name')
                                ->limit(50)
                                ->pluck('name', 'id')
                                ->all())
                            ->getOptionLabelsUsing(fn (array $values): array => User::query()
                                ->whereKey($values)
                                ->pluck('name', 'id')
                                ->all())
                            ->dehydrated()
                            ->visible($audienceIs(self::AUDIENCE_STUDENTS))
                            ->required($audienceIs(self::AUDIENCE_STUDENTS)),
                        Forms\Components\Select::make('audience_subject_id')
                            ->label('المادة')
                            ->helperText('يصل الإشعار إلى الطلاب المفعّلة لديهم هذه المادة.')
                            ->options(fn (): array => Subject::query()->orderBy('title')->pluck('title', 'id')->all())
                            ->searchable()
                            ->dehydrated()
                            ->visible($audienceIs(self::AUDIENCE_SUBJECT))
                            ->required($audienceIs(self::AUDIENCE_SUBJECT)),
                        Forms\Components\Placeholder::make('audience_note')
                            ->label('')
                            ->content('عند الإرسال لأكثر من طالب يصل الإشعار داخل التطبيق وكإشعار فوري، ولا تُرسل نسخة بالبريد.')
                            ->visible(fn (Get $get, string $operation): bool => $operation === 'create'
                                && ($get('audience') ?? self::AUDIENCE_USER) !== self::AUDIENCE_USER)
                            ->columnSpanFull(),
                    ])
                    ->columns(2),
                Forms\Components\Section::make('المحتوى')
                    ->schema([
                        Forms\Components\TextInput::make('title')
                            ->label('العنوان')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\Select::make('type')
                            ->label('النوع')
                            ->options(fn (string $operation): array => $operation === 'create'
                                ? AppNotificationType::manualFormOptions()
                                : AppNotificationType::options())
                            ->default(AppNotificationType::Custom->value)
                            ->live()
                            ->required(),
                        Forms\Components\Textarea::make('body')
                            ->label('المحتوى')
                            ->required()
                            ->maxLength(2000)
                            ->rows(5)
                            ->columnSpanFull(),
                    ])
                    ->columns(2),
                Forms\Components\Section::make('الصفحة التي تُفتح عند الضغط')
                    ->description('اختياري. بدونها يفتح التطبيق القائمة المناسبة لنوع الإشعار.')
                    ->schema([
                        Forms\Components\Select::make('target_subject_id')
                            ->label('المادة')
                            ->options(fn (): array => Subject::query()->orderBy('title')->pluck('title', 'id')->all())
                            ->searchable()
                            ->live()
                            ->dehydrated()
                            ->visible($typeIn([
                                AppNotificationType::LessonPublished->value,
                                AppNotificationType::SubjectActivated->value,
                                AppNotificationType::Custom->value,
                            ])),
                        Forms\Components\Select::make('target_lesson_id')
                            ->label('المحاضرة')
                            ->options(fn (Get $get): array => filled($get('target_subject_id'))
                                ? Lesson::query()->where('subject_id', $get('target_subject_id'))->orderBy('order')->pluck('title', 'id')->all()
                                : [])
                            ->searchable()
                            ->dehydrated()
                            ->visible($typeIn([AppNotificationType::LessonPublished->value])),
                        Forms\Components\Select::make('target_assignment_id')
                            ->label('الواجب')
                            ->options(fn (): array => Assignment::query()->latest()->limit(200)->pluck('title', 'id')->all())
                            ->searchable()
                            ->dehydrated()
                            ->visible($typeIn([AppNotificationType::AssignmentCreated->value])),
                        Forms\Components\Select::make('target_quiz_id')
                            ->label('الاختبار')
                            ->options(fn (): array => Quiz::query()->latest()->limit(200)->pluck('title', 'id')->all())
                            ->searchable()
                            ->dehydrated()
                            ->visible($typeIn([AppNotificationType::QuizCreated->value])),
                        Forms\Components\Select::make('target_announcement_id')
                            ->label('الإعلان')
                            ->options(fn (): array => Announcement::query()->latest()->limit(200)->pluck('title', 'id')->all())
                            ->searchable()
                            ->dehydrated()
                            ->visible($typeIn([AppNotificationType::Announcement->value])),
                    ])
                    ->columns(2)
                    ->visible(fn (Get $get, string $operation): bool => $operation === 'create' && in_array($get('type'), [
                        AppNotificationType::LessonPublished->value,
                        AppNotificationType::SubjectActivated->value,
                        AppNotificationType::Custom->value,
                        AppNotificationType::AssignmentCreated->value,
                        AppNotificationType::QuizCreated->value,
                        AppNotificationType::Announcement->value,
                    ], true)),
                Forms\Components\Section::make('الحالة')
                    ->schema([
                        Forms\Components\Toggle::make('is_read')
                            ->label('مقروء')
                            ->helperText('الإشعار المقروء لا يُرسل كإشعار فوري.')
                            ->default(false),
                    ])
                    ->visible(fn (string $operation): bool => $operation !== 'create'),
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
