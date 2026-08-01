<?php

namespace App\Filament\Resources\ExpenseResource\Pages;

use App\Filament\Concerns\LogsExpenseAudit;
use App\Filament\Resources\ExpenseResource;
use Filament\Resources\Pages\CreateRecord;

class CreateExpense extends CreateRecord
{
    use LogsExpenseAudit;

    protected static string $resource = ExpenseResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $data['created_by'] = auth()->id();

        return $data;
    }

    protected function afterCreate(): void
    {
        $amount = number_format((float) $this->record->amount, 2);

        $this->logExpenseAudit(
            action: 'expense.created',
            expense: $this->record,
            description: 'تم إضافة مصروف «'.$this->record->title.'» بقيمة '.$amount.' د.أ.',
        );
    }

    protected function getCreatedNotificationTitle(): ?string
    {
        return 'تم إضافة المصروف';
    }
}
