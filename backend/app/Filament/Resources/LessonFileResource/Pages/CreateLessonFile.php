<?php

namespace App\Filament\Resources\LessonFileResource\Pages;

use App\Enums\FileType;
use App\Filament\Resources\LessonFileResource;
use App\Jobs\UploadLessonFileToBunnyJob;
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

    protected function afterCreate(): void
    {
        if ($this->record->file_type === FileType::Pdf && filled($this->record->file_path)) {
            UploadLessonFileToBunnyJob::dispatch($this->record->id);
        }
    }
}
