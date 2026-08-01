<?php

namespace App\Filament\Resources\SubjectResource\Pages;

use App\Filament\Concerns\HasInstructorScope;
use App\Filament\Resources\SubjectResource;
use Filament\Resources\Pages\CreateRecord;

class CreateSubject extends CreateRecord
{
    use HasInstructorScope;

    protected static string $resource = SubjectResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        if (static::isInstructor()) {
            $data['instructor_id'] = static::authUser()?->id;
        }

        return $data;
    }
}
