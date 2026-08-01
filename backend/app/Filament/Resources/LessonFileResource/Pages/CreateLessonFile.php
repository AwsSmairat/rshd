<?php

namespace App\Filament\Resources\LessonFileResource\Pages;

use App\Filament\Resources\LessonFileResource;
use Filament\Resources\Pages\CreateRecord;

class CreateLessonFile extends CreateRecord
{
    protected static string $resource = LessonFileResource::class;

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    protected function mutateFormDataBeforeCreate(array $data): array
    {
        return LessonFileResource::prepareFileData($data);
    }
}
