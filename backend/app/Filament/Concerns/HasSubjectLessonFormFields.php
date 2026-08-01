<?php

namespace App\Filament\Concerns;

use App\Models\Lesson;
use App\Models\Subject;
use Filament\Forms;
use Filament\Forms\Get;
use Filament\Forms\Set;
use Illuminate\Database\Eloquent\Model;

trait HasSubjectLessonFormFields
{
    /**
     * Subject → lesson cascading selects.
     *
     * @return array<int, Forms\Components\Component>
     */
    protected static function subjectThenLessonFields(
        bool $subjectPersistsOnModel = false,
        bool $lessonRequired = true,
        string $lessonLabel = 'الجزء',
    ): array {
        $subjectField = Forms\Components\Select::make('subject_id')
            ->label('المادة')
            ->options(fn (): array => static::scopeSubjectsQuery(Subject::query())
                ->orderBy('title')
                ->pluck('title', 'id')
                ->all())
            ->searchable()
            ->preload()
            ->required()
            ->live()
            ->afterStateUpdated(fn (Set $set) => $set('lesson_id', null))
            ->afterStateHydrated(function (Forms\Components\Select $component, mixed $state, ?Model $record): void {
                if (filled($state) || $record === null) {
                    return;
                }

                $record->loadMissing('lesson');
                $component->state($record->lesson?->subject_id);
            });

        if (! $subjectPersistsOnModel) {
            $subjectField->dehydrated(false);
        }

        $lessonField = Forms\Components\Select::make('lesson_id')
            ->label($lessonLabel)
            ->options(function (Get $get): array {
                $subjectId = $get('subject_id');

                if (blank($subjectId)) {
                    return [];
                }

                return static::scopeLessonsQuery(Lesson::query())
                    ->where('subject_id', $subjectId)
                    ->orderBy('order')
                    ->orderBy('title')
                    ->pluck('title', 'id')
                    ->all();
            })
            ->searchable()
            ->preload()
            ->live()
            ->disabled(fn (Get $get): bool => blank($get('subject_id')))
            ->helperText(fn (Get $get): ?string => blank($get('subject_id'))
                ? 'اختر المادة أولاً لإظهار الأجزاء.'
                : null)
            ->required($lessonRequired);

        return [$subjectField, $lessonField];
    }
}
