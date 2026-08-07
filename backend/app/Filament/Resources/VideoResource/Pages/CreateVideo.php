<?php

namespace App\Filament\Resources\VideoResource\Pages;

use App\Filament\Resources\VideoResource;
use App\Jobs\UploadVideoToBunnyJob;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Database\Eloquent\Model;

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

    /**
     * @param  array<string, mixed>  $data
     */
    protected function handleRecordCreation(array $data): Model
    {
        $data = VideoResource::prepareVideoData($data);

        $record = new ($this->getModel())($data);
        $record->save();

        return $record;
    }

    protected function afterCreate(): void
    {
        if ($this->record->storage_provider === 'bunny' && $this->record->video_path) {
            UploadVideoToBunnyJob::dispatch($this->record->id);
        }
    }
}
