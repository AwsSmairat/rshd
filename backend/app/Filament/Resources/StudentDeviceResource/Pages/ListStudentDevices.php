<?php

namespace App\Filament\Resources\StudentDeviceResource\Pages;

use App\Filament\Resources\StudentDeviceResource;
use Filament\Resources\Pages\ListRecords;

class ListStudentDevices extends ListRecords
{
    protected static string $resource = StudentDeviceResource::class;

    protected function getHeaderActions(): array
    {
        return [];
    }
}
