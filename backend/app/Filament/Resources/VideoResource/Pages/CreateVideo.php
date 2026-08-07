<?php

namespace App\Filament\Resources\VideoResource\Pages;

use App\Filament\Resources\VideoResource;
use App\Jobs\UploadVideoToBunnyJob;
use Filament\Resources\Pages\CreateRecord;

class CreateVideo extends CreateRecord
{
    protected static string $resource = VideoResource::class;

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    protected function mutateFormDataBeforeCreate(array $data): array
    {
        return VideoResource::prepareVideoData($data);
    }

    protected function afterCreate(): void
    {
        if ($this->record->storage_provider === 'bunny' && $this->record->video_path) {
            UploadVideoToBunnyJob::dispatch($this->record->id);
        }
    }
}
