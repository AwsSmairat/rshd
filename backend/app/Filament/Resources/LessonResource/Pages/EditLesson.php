<?php

namespace App\Filament\Resources\LessonResource\Pages;

use App\Filament\Resources\LessonResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditLesson extends EditRecord
{
    protected static string $resource = LessonResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    protected function mutateFormDataBeforeSave(array $data): array
    {
        /** @var \App\Models\Lesson $record */
        $record = $this->record;

        $subjectId = (int) ($data['subject_id'] ?? $record->subject_id);

        if ($subjectId !== (int) $record->subject_id) {
            $data['order'] = LessonResource::nextOrderForSubject($subjectId, $record->id);
        } else {
            $data['order'] = $record->order > 0
                ? $record->order
                : LessonResource::nextOrderForSubject($subjectId, $record->id);
        }

        return $data;
    }
}
