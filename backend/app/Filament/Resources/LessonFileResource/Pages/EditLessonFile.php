<?php

namespace App\Filament\Resources\LessonFileResource\Pages;

use App\Filament\Resources\LessonFileResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditLessonFile extends EditRecord
{
    protected static string $resource = LessonFileResource::class;

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
        /** @var \App\Models\LessonFile $record */
        $record = $this->record;

        return LessonFileResource::prepareFileData($data, $record);
    }
}
