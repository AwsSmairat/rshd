<?php

namespace App\Filament\Resources;

use App\Enums\ContentStatus;
use App\Enums\SubjectCategory;
use App\Enums\UserRole;
use App\Filament\Concerns\ChecksPlatformInstructorSettings;
use App\Filament\Concerns\HasInstructorScope;
use App\Filament\Resources\SubjectResource\Pages;
use App\Models\Subject;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class SubjectResource extends Resource
{
    use ChecksPlatformInstructorSettings;
    use HasInstructorScope;

    protected static ?string $model = Subject::class;

    protected static ?string $navigationIcon = 'heroicon-o-book-open';

    protected static ?string $navigationGroup = 'التعليم';

    protected static ?string $navigationLabel = 'المواد';

    protected static ?string $modelLabel = 'مادة';

    protected static ?string $pluralModelLabel = 'المواد';

    protected static ?int $navigationSort = 1;

    public static function getEloquentQuery(): Builder
    {
        return static::scopeSubjectsQuery(parent::getEloquentQuery());
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('معلومات المادة')
                    ->schema([
                        Forms\Components\TextInput::make('title')
                            ->label('العنوان')
                            ->required()
                            ->maxLength(255)
                            ->columnSpanFull(),
                        Forms\Components\Textarea::make('description')
                            ->label('الوصف')
                            ->rows(4)
                            ->columnSpanFull(),
                        Forms\Components\Select::make('category')
                            ->label('التصنيف')
                            ->options(SubjectCategory::options())
                            ->required(),
                        Forms\Components\FileUpload::make('cover_image')
                            ->label('صورة الغلاف')
                            ->image()
                            ->disk('public')
                            ->directory('subjects/covers')
                            ->visibility('public')
                            ->imageEditor()
                            ->helperText('تظهر للطالب في قائمة المواد وتفاصيل المادة.')
                            ->columnSpanFull(),
                    ])
                    ->columns(2),
                Forms\Components\Section::make('الإعدادات')
                    ->schema([
                        Forms\Components\Select::make('instructor_id')
                            ->label('المدرس')
                            ->relationship(
                                'instructor',
                                'name',
                                fn (Builder $query) => $query->where('role', UserRole::Instructor),
                            )
                            ->searchable()
                            ->preload()
                            ->required()
                            ->default(fn (): ?int => static::isInstructor() ? static::authUser()?->id : null)
                            ->disabled(fn (): bool => static::isInstructor())
                            ->dehydrated()
                            ->visible(fn (): bool => static::isAdmin()),
                        Forms\Components\Select::make('status')
                            ->label('الحالة')
                            ->options(ContentStatus::options())
                            ->default(ContentStatus::Active->value)
                            ->required(),
                        Forms\Components\TextInput::make('price')
                            ->label('سعر المادة')
                            ->numeric()
                            ->minValue(0)
                            ->suffix('د.أ')
                            ->helperText('السعر الافتراضي عند تفعيل الطالب للمادة.'),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->withCount(['lessons', 'enrollments']))
            ->defaultSort('title')
            ->columns([
                Tables\Columns\ImageColumn::make('cover_image')
                    ->label('الغلاف')
                    ->disk('public')
                    ->circular()
                    ->defaultImageUrl(fn (): string => asset('images/rshd_logo_no_bg.png')),
                Tables\Columns\TextColumn::make('title')
                    ->label('العنوان')
                    ->searchable()
                    ->sortable()
                    ->limit(35),
                Tables\Columns\TextColumn::make('instructor.name')
                    ->label('المدرس')
                    ->sortable()
                    ->visible(fn (): bool => static::isAdmin()),
                Tables\Columns\TextColumn::make('category')
                    ->label('التصنيف')
                    ->badge()
                    ->formatStateUsing(function (SubjectCategory|string|null $state): string {
                        if ($state instanceof SubjectCategory) {
                            return $state->label();
                        }

                        return SubjectCategory::tryFrom((string) $state)?->label() ?? (string) $state;
                    })
                    ->color(fn (SubjectCategory|string|null $state): string => match ($state instanceof SubjectCategory ? $state : SubjectCategory::tryFrom((string) $state)) {
                        SubjectCategory::Medicine => 'danger',
                        SubjectCategory::It => 'info',
                        SubjectCategory::Engineering => 'warning',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('status')
                    ->label('الحالة')
                    ->badge()
                    ->formatStateUsing(function (ContentStatus|string|null $state): string {
                        if ($state instanceof ContentStatus) {
                            return $state->label();
                        }

                        return ContentStatus::tryFrom((string) $state)?->label() ?? (string) $state;
                    })
                    ->color(fn (ContentStatus|string|null $state): string => match ($state instanceof ContentStatus ? $state : ContentStatus::tryFrom((string) $state)) {
                        ContentStatus::Active => 'success',
                        ContentStatus::Inactive => 'gray',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('lessons_count')
                    ->label('الدروس')
                    ->sortable()
                    ->alignCenter(),
                Tables\Columns\TextColumn::make('enrollments_count')
                    ->label('المسجلون')
                    ->sortable()
                    ->alignCenter(),
                Tables\Columns\TextColumn::make('price')
                    ->label('السعر')
                    ->formatStateUsing(fn (?string $state): string => number_format((float) ($state ?? 0), 3).' د.أ')
                    ->sortable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('category')
                    ->label('التصنيف')
                    ->options(SubjectCategory::options()),
                Tables\Filters\SelectFilter::make('status')
                    ->label('الحالة')
                    ->options(ContentStatus::options()),
                Tables\Filters\SelectFilter::make('instructor_id')
                    ->label('المدرس')
                    ->relationship(
                        'instructor',
                        'name',
                        fn (Builder $query) => $query->where('role', UserRole::Instructor),
                    )
                    ->searchable()
                    ->preload()
                    ->visible(fn (): bool => static::isAdmin()),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->emptyStateHeading('لا توجد مواد')
            ->emptyStateDescription('ابدأ بإضافة أول مادة من زر «إضافة مادة».')
            ->emptyStateIcon('heroicon-o-book-open');
    }

    public static function canCreate(): bool
    {
        return static::instructorMay('instructor_can_create_subjects');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListSubjects::route('/'),
            'create' => Pages\CreateSubject::route('/create'),
            'edit' => Pages\EditSubject::route('/{record}/edit'),
        ];
    }
}
