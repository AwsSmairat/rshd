<?php

namespace App\Filament\Resources\LegalDocumentResource\Pages;

use App\Enums\LegalDocumentStatus;
use App\Filament\Resources\LegalDocumentResource;
use App\Services\LegalDocumentService;
use Filament\Actions;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\EditRecord;
use Illuminate\Database\Eloquent\Model;

class EditLegalDocument extends EditRecord
{
    protected static string $resource = LegalDocumentResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\ViewAction::make()
                ->label('معاينة'),
            Actions\Action::make('publish')
                ->label('نشر النسخة')
                ->icon('heroicon-o-check-badge')
                ->color('success')
                ->visible(fn (): bool => $this->record->isDraft())
                ->requiresConfirmation()
                ->modalHeading('نشر الوثيقة القانونية')
                ->modalDescription(
                    'سيتم نشر هذه النسخة وجعلها الحالية للمستخدمين. '
                    .'النسخة المنشورة السابقة ستُحفظ كنسخة سابقة ولا تُحذف.'
                )
                ->modalSubmitActionLabel('نعم، انشر الآن')
                ->action(function (LegalDocumentService $legalDocuments): void {
                    try {
                        $legalDocuments->publish($this->record->fresh());
                        $this->record->refresh();
                        Notification::make()
                            ->title('تم نشر الوثيقة')
                            ->success()
                            ->send();
                    } catch (\InvalidArgumentException $exception) {
                        Notification::make()
                            ->title('تعذر النشر')
                            ->body($exception->getMessage())
                            ->danger()
                            ->send();
                    }
                }),
            Actions\DeleteAction::make()
                ->visible(fn (): bool => app(LegalDocumentService::class)->canDelete($this->record))
                ->before(function (): void {
                    if (! app(LegalDocumentService::class)->canDelete($this->record)) {
                        Notification::make()
                            ->title('لا يمكن الحذف')
                            ->body('هذه النسخة مرتبطة بموافقات طلاب ولا يمكن حذفها.')
                            ->danger()
                            ->send();

                        $this->halt();
                    }
                }),
        ];
    }

    protected function handleRecordUpdate(Model $record, array $data): Model
    {
        if ($record->status !== LegalDocumentStatus::Draft) {
            Notification::make()
                ->title('لا يمكن التعديل')
                ->body('النسخ المنشورة محفوظة للتدقيق. أنشئ مسودة جديدة.')
                ->danger()
                ->send();

            $this->halt();
        }

        return parent::handleRecordUpdate($record, $data);
    }

    protected function getSavedNotificationTitle(): ?string
    {
        return 'تم حفظ المسودة';
    }
}
