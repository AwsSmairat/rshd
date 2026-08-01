<?php

namespace App\Filament\Resources\ExpenseResource\Pages;

use App\Filament\Concerns\LogsExpenseAudit;
use App\Filament\Resources\ExpenseResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditExpense extends EditRecord
{
    use LogsExpenseAudit;

    protected static string $resource = ExpenseResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make()
                ->before(function (): void {
                    $this->logExpenseAudit(
                        action: 'expense.deleted',
                        expense: $this->record,
                        description: 'تم حذف مصروف «'.$this->record->title.'».',
                    );
                }),
        ];
    }

    protected function afterSave(): void
    {
        $amount = number_format((float) $this->record->amount, 2);

        $this->logExpenseAudit(
            action: 'expense.updated',
            expense: $this->record,
            description: 'تم تحديث مصروف «'.$this->record->title.'» ('.$amount.' د.أ).',
        );
    }

    protected function getSavedNotificationTitle(): ?string
    {
        return 'تم تحديث المصروف';
    }
}
