<?php

namespace App\Filament\Resources\LessonFileResource\Pages;

use App\Enums\FileType;
use App\Enums\LessonFileStorageStatus;
use App\Filament\Resources\LessonFileResource;
use App\Jobs\UploadLessonFileToBunnyJob;
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

    protected function afterSave(): void
    {
        $record = $this->record->fresh();

        if ($record === null) {
            return;
        }

        if ($record->file_type === FileType::Pdf
            && filled($record->file_path)
            && $record->storage_status === LessonFileStorageStatus::Pending) {
            UploadLessonFileToBunnyJob::dispatch($record->id);
        }
    }
}
