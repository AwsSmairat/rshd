<?php

namespace App\Filament\Resources\SubjectStudentResource\Pages;

use App\Filament\Resources\SubjectStudentResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListSubjectStudents extends ListRecords
{
    protected static string $resource = SubjectStudentResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make()
                ->label('تفعيل مادة لطالب'),
        ];
    }
}
