<?php

namespace App\Filament\Resources;

use App\Enums\QuestionType;
use App\Filament\Concerns\HasInstructorScope;
use App\Filament\Resources\QuizQuestionResource\Pages;
use App\Filament\Resources\QuizQuestionResource\RelationManagers\AnswersRelationManager;
use App\Models\QuizQuestion;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class QuizQuestionResource extends Resource
{
    use HasInstructorScope;

    protected static ?string $model = QuizQuestion::class;

    protected static ?string $navigationIcon = 'heroicon-o-list-bullet';

    protected static ?string $navigationGroup = 'التعليم';

    protected static ?string $navigationLabel = 'أسئلة الاختبار';

    protected static ?string $modelLabel = 'سؤال';

    protected static ?string $pluralModelLabel = 'أسئلة الاختبار';

    protected static ?int $navigationSort = 8;

    public static function getEloquentQuery(): Builder
    {
        return static::scopeBySubjectInstructor(
            parent::getEloquentQuery(),
            'quiz.subject',
        );
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('السؤال')
                    ->schema([
                        Forms\Components\Select::make('quiz_id')
                            ->label('الاختبار')
                            ->relationship(
                                'quiz',
                                'title',
                                fn (Builder $query) => static::scopeBySubjectInstructor($query, 'subject'),
                            )
                            ->searchable()
                            ->preload()
                            ->required(),
                        Forms\Components\Textarea::make('question_text')
                            ->label('نص السؤال')
                            ->required()
                            ->rows(4)
                            ->columnSpanFull(),
                        Forms\Components\Select::make('question_type')
                            ->label('نوع السؤال')
                            ->options(QuestionType::options())
                            ->default(QuestionType::Mcq->value)
                            ->required(),
                        Forms\Components\TextInput::make('points')
                            ->label('الدرجة')
                            ->numeric()
                            ->minValue(1)
                            ->default(1)
                            ->required()
                            ->suffix('نقطة'),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->withCount('answers'))
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('quiz.title')
                    ->label('الاختبار')
                    ->sortable()
                    ->searchable()
                    ->limit(28),
                Tables\Columns\TextColumn::make('quiz.subject.title')
                    ->label('المادة')
                    ->sortable()
                    ->toggleable(),
                Tables\Columns\TextColumn::make('question_text')
                    ->label('السؤال')
                    ->limit(50)
                    ->searchable(),
                Tables\Columns\TextColumn::make('question_type')
                    ->label('النوع')
                    ->badge()
                    ->formatStateUsing(function (QuestionType|string|null $state): string {
                        if ($state instanceof QuestionType) {
                            return $state->label();
                        }

                        return QuestionType::tryFrom((string) $state)?->label() ?? (string) $state;
                    })
                    ->color(fn (QuestionType|string|null $state): string => match ($state instanceof QuestionType ? $state : QuestionType::tryFrom((string) $state)) {
                        QuestionType::Mcq => 'info',
                        QuestionType::TrueFalse => 'warning',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('answers_count')
                    ->label('الإجابات')
                    ->sortable()
                    ->alignCenter(),
                Tables\Columns\TextColumn::make('points')
                    ->label('الدرجة')
                    ->sortable()
                    ->alignCenter(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('quiz_id')
                    ->label('الاختبار')
                    ->relationship(
                        'quiz',
                        'title',
                        fn (Builder $query) => static::scopeBySubjectInstructor($query, 'subject'),
                    )
                    ->searchable()
                    ->preload(),
                Tables\Filters\SelectFilter::make('question_type')
                    ->label('النوع')
                    ->options(QuestionType::options()),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->emptyStateHeading('لا توجد أسئلة')
            ->emptyStateDescription('أنشئ اختباراً أولاً من «الاختبارات»، ثم أضف أسئله من زر «إضافة سؤال».')
            ->emptyStateIcon('heroicon-o-list-bullet');
    }

    public static function getRelations(): array
    {
        return [
            AnswersRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListQuizQuestions::route('/'),
            'create' => Pages\CreateQuizQuestion::route('/create'),
            'edit' => Pages\EditQuizQuestion::route('/{record}/edit'),
        ];
    }
}
