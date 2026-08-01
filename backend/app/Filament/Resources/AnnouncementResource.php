<?php

namespace App\Filament\Resources;

use App\Enums\AnnouncementTargetType;
use App\Enums\AnnouncementType;
use App\Enums\UserRole;
use App\Filament\Concerns\ChecksPlatformInstructorSettings;
use App\Filament\Concerns\HasInstructorScope;
use App\Filament\Resources\AnnouncementResource\Pages;
use App\Models\Announcement;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Forms\Get;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class AnnouncementResource extends Resource
{
    use ChecksPlatformInstructorSettings;
    use HasInstructorScope;

    protected static ?string $model = Announcement::class;

    protected static ?string $navigationIcon = 'heroicon-o-megaphone';

    protected static ?string $navigationGroup = 'التقويم والتواصل';

    protected static ?string $navigationLabel = 'الإعلانات';

    protected static ?string $modelLabel = 'إعلان';

    protected static ?string $pluralModelLabel = 'الإعلانات';

    protected static ?int $navigationSort = 3;

    public static function canAccess(): bool
    {
        $user = auth()->user();

        if ($user?->isAdmin()) {
            return true;
        }

        return static::instructorMay('instructor_can_publish_announcements');
    }

    public static function canCreate(): bool
    {
        return static::instructorMay('instructor_can_publish_announcements');
    }

    public static function shouldRegisterNavigation(): bool
    {
        return static::canAccess();
    }

    public static function getEloquentQuery(): Builder
    {
        $query = parent::getEloquentQuery();

        if (static::isAdmin()) {
            return $query;
        }

        return $query->where('instructor_id', static::authUser()?->id);
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('تفاصيل الإعلان')
                    ->schema([
                        Forms\Components\TextInput::make('title')
                            ->label('العنوان')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\Textarea::make('body')
                            ->label('المحتوى')
                            ->required()
                            ->rows(5)
                            ->columnSpanFull(),
                        Forms\Components\FileUpload::make('image')
                            ->label('صورة الإعلان')
                            ->helperText('تظهر في مربع الإعلانات بالصفحة الرئيسية')
                            ->image()
                            ->directory('announcements')
                            ->disk('public')
                            ->visibility('public')
                            ->imageEditor()
                            ->columnSpanFull(),
                    ])
                    ->columns(2),
                Forms\Components\Section::make('الاستهداف')
                    ->schema([
                        Forms\Components\Select::make('type')
                            ->label('النوع')
                            ->options(AnnouncementType::options())
                            ->default(AnnouncementType::General->value)
                            ->required(),
                        Forms\Components\Select::make('target_type')
                            ->label('الجمهور')
                            ->options(AnnouncementTargetType::formOptions())
                            ->default(AnnouncementTargetType::Subject->value)
                            ->required()
                            ->live(),
                        Forms\Components\Select::make('subject_id')
                            ->label('المادة')
                            ->relationship(
                                'subject',
                                'title',
                                fn (Builder $query) => static::scopeSubjectsQuery($query),
                            )
                            ->searchable()
                            ->preload()
                            ->visible(fn (Get $get): bool => $get('target_type') === AnnouncementTargetType::Subject->value)
                            ->required(fn (Get $get): bool => $get('target_type') === AnnouncementTargetType::Subject->value),
                        Forms\Components\Select::make('instructor_id')
                            ->label('المدرس')
                            ->relationship(
                                'instructor',
                                'name',
                                fn (Builder $query) => $query->where('role', UserRole::Instructor),
                            )
                            ->searchable()
                            ->preload()
                            ->default(fn (): ?int => static::isInstructor() ? static::authUser()?->id : null)
                            ->disabled(fn (): bool => static::isInstructor())
                            ->dehydrated()
                            ->visible(fn (): bool => static::isAdmin()),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\ImageColumn::make('image')
                    ->label('الصورة')
                    ->disk('public')
                    ->circular(),
                Tables\Columns\TextColumn::make('title')
                    ->label('العنوان')
                    ->searchable()
                    ->limit(40),
                Tables\Columns\TextColumn::make('type')
                    ->label('النوع')
                    ->badge()
                    ->formatStateUsing(function (AnnouncementType|string|null $state): string {
                        if ($state instanceof AnnouncementType) {
                            return $state->label();
                        }

                        return AnnouncementType::tryFrom((string) $state)?->label() ?? (string) $state;
                    })
                    ->color(fn (AnnouncementType|string|null $state): string => match ($state instanceof AnnouncementType ? $state : AnnouncementType::tryFrom((string) $state)) {
                        AnnouncementType::Important => 'danger',
                        AnnouncementType::Subject => 'info',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('subject.title')
                    ->label('المادة')
                    ->placeholder('—'),
                Tables\Columns\TextColumn::make('instructor.name')
                    ->label('المدرس')
                    ->visible(fn (): bool => static::isAdmin()),
                Tables\Columns\TextColumn::make('target_type')
                    ->label('الجمهور')
                    ->badge()
                    ->formatStateUsing(function (AnnouncementTargetType|string|null $state): string {
                        if ($state instanceof AnnouncementTargetType) {
                            return $state->label();
                        }

                        return AnnouncementTargetType::tryFrom((string) $state)?->label() ?? (string) $state;
                    })
                    ->color(fn (AnnouncementTargetType|string|null $state): string => match ($state instanceof AnnouncementTargetType ? $state : AnnouncementTargetType::tryFrom((string) $state)) {
                        AnnouncementTargetType::All => 'success',
                        AnnouncementTargetType::Subject => 'warning',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('Y-m-d H:i')
                    ->sortable(),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->emptyStateHeading('لا توجد إعلانات')
            ->emptyStateDescription('ابدأ بنشر أول إعلان للطلاب من زر «إضافة إعلان».');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListAnnouncements::route('/'),
            'create' => Pages\CreateAnnouncement::route('/create'),
            'edit' => Pages\EditAnnouncement::route('/{record}/edit'),
        ];
    }
}
