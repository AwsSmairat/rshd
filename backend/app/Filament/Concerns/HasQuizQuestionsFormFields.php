<?php

namespace App\Filament\Concerns;

use App\Enums\QuestionType;
use Closure;
use Filament\Forms;
use Filament\Forms\Components\Component;
use Filament\Forms\Get;
use Filament\Forms\Set;
use Illuminate\Support\Str;

trait HasQuizQuestionsFormFields
{
    /**
     * @return array<int, Forms\Components\Component>
     */
    protected static function quizQuestionsEditor(): array
    {
        return [
            Forms\Components\Section::make('الأسئلة')
                ->description('أضف أسئلة الاختبار هنا، واكتب الخيارات، ثم حدّد الإجابة الصحيحة بالدائرة.')
                ->icon('heroicon-o-clipboard-document-list')
                ->extraAttributes(['class' => 'rshd-quiz-builder'])
                ->schema([
                    Forms\Components\Repeater::make('questions')
                        ->relationship()
                        ->label('')
                        ->addActionLabel('إضافة سؤال')
                        ->defaultItems(1)
                        ->minItems(1)
                        ->collapsible()
                        ->cloneable()
                        ->itemLabel(fn (array $state): string => filled($state['question_text'] ?? null)
                            ? (string) Str::limit(strip_tags((string) $state['question_text']), 48)
                            : 'سؤال جديد')
                        ->schema([
                            Forms\Components\Textarea::make('question_text')
                                ->label('نص السؤال')
                                ->placeholder('اكتب السؤال هنا...')
                                ->required()
                                ->rows(3)
                                ->columnSpanFull(),
                            Forms\Components\Select::make('question_type')
                                ->label('نوع السؤال')
                                ->options(QuestionType::options())
                                ->default(QuestionType::Mcq->value)
                                ->required()
                                ->live()
                                ->afterStateUpdated(function (mixed $state, Set $set): void {
                                    static::fillAnswersForQuestionType(is_string($state) ? $state : null, $set);
                                }),
                            Forms\Components\TextInput::make('points')
                                ->label('الدرجة')
                                ->numeric()
                                ->minValue(1)
                                ->default(1)
                                ->required()
                                ->suffix('نقطة'),
                            static::quizAnswersRepeater(),
                        ])
                        ->columns(2)
                        ->columnSpanFull(),
                ])
                ->columnSpanFull(),
        ];
    }

    protected static function quizAnswersRepeater(): Forms\Components\Repeater
    {
        return Forms\Components\Repeater::make('answers')
            ->relationship()
            ->label('الخيارات')
            ->helperText('ظلل الدائرة بجانب الإجابة الصحيحة. يجب اختيار إجابة واحدة فقط.')
            ->addActionLabel('إضافة خيار')
            ->defaultItems(4)
            ->minItems(2)
            ->maxItems(fn (Get $get): int => $get('question_type') === QuestionType::TrueFalse->value ? 2 : 8)
            ->addable(fn (Get $get): bool => $get('question_type') !== QuestionType::TrueFalse->value)
            ->deletable(fn (Get $get): bool => $get('question_type') !== QuestionType::TrueFalse->value)
            ->reorderable(false)
            ->schema([
                Forms\Components\Grid::make(12)
                    ->schema([
                        Forms\Components\Checkbox::make('is_correct')
                            ->label('صحيحة')
                            ->live()
                            ->afterStateUpdated(function (?bool $state, Component $component): void {
                                if ($state === true) {
                                    static::selectSingleCorrectAnswer($component);
                                }
                            })
                            ->extraFieldWrapperAttributes(['class' => 'rshd-quiz-correct'])
                            ->columnSpan(2),
                        Forms\Components\TextInput::make('answer_text')
                            ->label('نص الخيار')
                            ->hiddenLabel()
                            ->placeholder('نص الخيار')
                            ->required()
                            ->columnSpan(10),
                    ]),
            ])
            ->rules([
                fn (): Closure => function (string $attribute, mixed $value, Closure $fail): void {
                    if (! is_array($value)) {
                        return;
                    }

                    $correctCount = collect($value)
                        ->filter(fn (mixed $answer): bool => is_array($answer) && static::isTruthy($answer['is_correct'] ?? false))
                        ->count();

                    if ($correctCount !== 1) {
                        $fail('حدد إجابة صحيحة واحدة بالدائرة لكل سؤال.');
                    }
                },
            ])
            ->columnSpanFull();
    }

    protected static function fillAnswersForQuestionType(?string $type, Set $set): void
    {
        if ($type === QuestionType::TrueFalse->value) {
            $set('answers', [
                ['answer_text' => 'صح', 'is_correct' => true],
                ['answer_text' => 'خطأ', 'is_correct' => false],
            ]);

            return;
        }

        $set('answers', [
            ['answer_text' => '', 'is_correct' => true],
            ['answer_text' => '', 'is_correct' => false],
            ['answer_text' => '', 'is_correct' => false],
            ['answer_text' => '', 'is_correct' => false],
        ]);
    }

    protected static function selectSingleCorrectAnswer(Component $component): void
    {
        $statePath = $component->getStatePath();

        if (! str_ends_with($statePath, '.is_correct')) {
            return;
        }

        $itemPath = substr($statePath, 0, -strlen('.is_correct'));
        $separator = strrpos($itemPath, '.');

        if ($separator === false) {
            return;
        }

        $answersPath = substr($itemPath, 0, $separator);
        $currentKey = substr($itemPath, $separator + 1);
        $livewire = $component->getLivewire();
        $answers = data_get($livewire, $answersPath);

        if (! is_array($answers)) {
            return;
        }

        foreach (array_keys($answers) as $key) {
            if ((string) $key === (string) $currentKey) {
                continue;
            }

            data_set($livewire, $answersPath.'.'.$key.'.is_correct', false);
        }
    }

    protected static function isTruthy(mixed $value): bool
    {
        return $value === true || $value === 1 || $value === '1' || $value === 'true';
    }
}
