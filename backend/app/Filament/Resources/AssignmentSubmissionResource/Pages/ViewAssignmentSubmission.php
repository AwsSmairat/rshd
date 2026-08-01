<?php

namespace App\Filament\Resources\AssignmentSubmissionResource\Pages;

use App\Filament\Resources\AssignmentSubmissionResource;
use Filament\Actions;
use Filament\Resources\Pages\ViewRecord;

class ViewAssignmentSubmission extends ViewRecord
{
    protected static string $resource = AssignmentSubmissionResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\EditAction::make()
                ->label('تقييم'),
        ];
    }
}
