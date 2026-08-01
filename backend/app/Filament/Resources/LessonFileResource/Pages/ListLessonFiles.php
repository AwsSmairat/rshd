<?php

namespace App\Filament\Resources\LessonFileResource\Pages;

use App\Filament\Resources\LessonFileResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListLessonFiles extends ListRecords
{
    protected static string $resource = LessonFileResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make()
                ->label('إضافة ملف'),
        ];
    }
}
