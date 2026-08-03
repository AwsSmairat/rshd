<?php

namespace App\Filament\Resources;

use App\Enums\ContentStatus;
use App\Filament\Concerns\HasInstructorScope;
use App\Filament\Resources\LessonResource\Pages;
use App\Models\Lesson;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class LessonResource extends Resource
{
    use HasInstructorScope;

    protected static ?string $model = Lesson::class;

    protected static ?string $navigationIcon = 'heroicon-o-play';

    protected static ?string $navigationGroup = 'التعليم';

    protected static ?string $navigationLabel = 'الأجزاء';

    protected static ?string $modelLabel = 'جزء';

    protected static ?string $pluralModelLabel = 'الأجزاء';

    protected static ?int $navigationSort = 3;

    public static function getEloquentQuery(): Builder
    {
        return static::scopeLessonsQuery(parent::getEloquentQuery());
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('معلومات الجزء')
                    ->schema([
                        Forms\Components\Select::make('subject_id')
                            ->label('المادة')
                            ->relationship(
                                'subject',
                                'title',
                                fn (Builder $query) => static::scopeSubjectsQuery($query),
                            )
                            ->searchable()
                            ->preload()
                            ->required(),
                        Forms\Components\TextInput::make('title')
                            ->label('اسم الجزء')
                            ->helperText('سمِّ الجزء كما تريد (مثال: مقدمة، الأسبوع ١، تيست...).')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\Textarea::make('description')
                            ->label('الوصف')
                            ->rows(4)
                            ->columnSpanFull(),
                    ])
                    ->columns(2),
                Forms\Components\Section::make('الحالة')
                    ->schema([
                        Forms\Components\Select::make('status')
                            ->label('الحالة')
                            ->options(ContentStatus::options())
                            ->default(ContentStatus::Active->value)
                            ->required(),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->withCount(['videos', 'assignments']))
            ->defaultSort('order')
            ->columns([
                Tables\Columns\TextColumn::make('subject.title')
                    ->label('المادة')
                    ->sortable()
                    ->searchable(),
                Tables\Columns\TextColumn::make('title')
                    ->label('اسم الجزء')
                    ->searchable()
                    ->sortable()
                    ->limit(35),
                Tables\Columns\TextColumn::make('order')
                    ->label('الترتيب')
                    ->sortable()
                    ->alignCenter(),
                Tables\Columns\TextColumn::make('videos_count')
                    ->label('فيديوهات')
                    ->sortable()
                    ->alignCenter(),
                Tables\Columns\TextColumn::make('assignments_count')
                    ->label('واجبات')
                    ->sortable()
                    ->alignCenter()
                    ->toggleable(isToggledHiddenByDefault: true),
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
                Tables\Columns\TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('subject_id')
                    ->label('المادة')
                    ->relationship(
                        'subject',
                        'title',
                        fn (Builder $query) => static::scopeSubjectsQuery($query),
                    )
                    ->searchable()
                    ->preload(),
                Tables\Filters\SelectFilter::make('status')
                    ->label('الحالة')
                    ->options(ContentStatus::options()),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->emptyStateHeading('لا توجد أجزاء')
            ->emptyStateDescription('قسّم المادة إلى أجزاء (أسابيع أو دروس) من زر «إضافة جزء».')
            ->emptyStateIcon('heroicon-o-play');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListLessons::route('/'),
            'create' => Pages\CreateLesson::route('/create'),
            'edit' => Pages\EditLesson::route('/{record}/edit'),
        ];
    }

    public static function nextOrderForSubject(int $subjectId, ?int $ignoreLessonId = null): int
    {
        $query = Lesson::query()->where('subject_id', $subjectId);

        if ($ignoreLessonId !== null) {
            $query->whereKeyNot($ignoreLessonId);
        }

        $maxOrder = (int) $query->max('order');

        return max(1, $maxOrder + 1);
    }
}
