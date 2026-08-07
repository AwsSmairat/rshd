<?php

namespace App\Filament\Resources\VideoResource\Pages;

use App\Enums\VideoStatus;
use App\Filament\Resources\VideoResource;
use App\Jobs\UploadVideoToBunnyJob;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditVideo extends EditRecord
{
    protected static string $resource = VideoResource::class;

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
        /** @var \App\Models\Video $record */
        $record = $this->record;

        return VideoResource::prepareVideoData($data, $record);
    }

    protected function afterSave(): void
    {
        if ($this->record->storage_provider !== 'bunny') {
            return;
        }

        if (! $this->record->wasChanged('video_path') || ! $this->record->video_path) {
            return;
        }

        $this->record->update([
            'external_video_id' => null,
            'status' => VideoStatus::Uploading,
        ]);

        UploadVideoToBunnyJob::dispatch($this->record->id);
    }
}
