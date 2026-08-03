<?php

namespace App\Filament\Resources\LessonResource\Pages;

use App\Filament\Resources\LessonResource;
use Filament\Resources\Pages\CreateRecord;

class CreateLesson extends CreateRecord
{
    protected static string $resource = LessonResource::class;

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $subjectId = (int) ($data['subject_id'] ?? 0);

        if ($subjectId > 0) {
            $data['order'] = LessonResource::nextOrderForSubject($subjectId);
        }

        return $data;
    }
}
