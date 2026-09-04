<?php

namespace App\Filament\Resources;

use App\Enums\ContentStatus;
use App\Filament\Concerns\ChecksPlatformInstructorSettings;
use App\Filament\Concerns\HasInstructorScope;
use App\Filament\Concerns\HasQuizQuestionsFormFields;
use App\Filament\Concerns\HasSubjectLessonFormFields;
use App\Filament\Resources\QuizResource\Pages;
use App\Models\Quiz;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class QuizResource extends Resource
{
    use ChecksPlatformInstructorSettings;
    use HasInstructorScope;
    use HasQuizQuestionsFormFields;
    use HasSubjectLessonFormFields;

    protected static ?string $model = Quiz::class;

    protected static ?string $navigationIcon = 'heroicon-o-question-mark-circle';

    protected static ?string $navigationGroup = 'التعليم';

    protected static ?string $navigationLabel = 'الاختبارات';

    protected static ?string $modelLabel = 'اختبار';

    protected static ?string $pluralModelLabel = 'الاختبارات';

    protected static ?int $navigationSort = 7;

    public static function getEloquentQuery(): Builder
    {
        return static::scopeBySubjectInstructor(parent::getEloquentQuery());
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('المادة والجزء')
                    ->schema([
                        ...static::subjectThenLessonFields(
                            subjectPersistsOnModel: true,
                            lessonRequired: false,
                            lessonLabel: 'الجزء',
                        ),
                    ])
                    ->columns(2),
                Forms\Components\Section::make('تفاصيل الاختبار')
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
                        Forms\Components\TextInput::make('duration_minutes')
                            ->label('المدة (دقائق)')
                            ->numeric()
                            ->minValue(1)
                            ->suffix('دقيقة'),
                        Forms\Components\Select::make('status')
                            ->label('الحالة')
                            ->options(ContentStatus::options())
                            ->default(ContentStatus::Active->value)
                            ->required(),
                    ])
                    ->columns(2),
                ...static::quizQuestionsEditor(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->withCount('questions'))
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('subject.title')
                    ->label('المادة')
                    ->sortable()
                    ->searchable(),
                Tables\Columns\TextColumn::make('lesson.title')
                    ->label('الجزء')
                    ->placeholder('—')
                    ->toggleable(),
                Tables\Columns\TextColumn::make('title')
                    ->label('العنوان')
                    ->searchable()
                    ->sortable()
                    ->limit(30),
                Tables\Columns\TextColumn::make('questions_count')
                    ->label('الأسئلة')
                    ->sortable()
                    ->alignCenter(),
                Tables\Columns\TextColumn::make('duration_minutes')
                    ->label('المدة (د)')
                    ->sortable()
                    ->placeholder('—'),
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
            ->emptyStateHeading('لا توجد اختبارات')
            ->emptyStateDescription('أنشئ أول اختبار من زر «إضافة اختبار».')
            ->emptyStateIcon('heroicon-o-question-mark-circle');
    }

    public static function canCreate(): bool
    {
        return static::instructorMay('instructor_can_create_quizzes');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListQuizzes::route('/'),
            'create' => Pages\CreateQuiz::route('/create'),
            'edit' => Pages\EditQuiz::route('/{record}/edit'),
        ];
    }
}
