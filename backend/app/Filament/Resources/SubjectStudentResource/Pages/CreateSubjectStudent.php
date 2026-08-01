<?php

namespace App\Filament\Resources\SubjectStudentResource\Pages;

use App\Enums\AccessStatus;
use App\Enums\PaymentStatus;
use App\Filament\Concerns\HasInstructorScope;
use App\Filament\Resources\SubjectStudentResource;
use App\Models\Subject;
use Filament\Resources\Pages\CreateRecord;

class CreateSubjectStudent extends CreateRecord
{
    use HasInstructorScope;

    protected static string $resource = SubjectStudentResource::class;

    public function getTitle(): string
    {
        return 'تفعيل مادة لطالب';
    }

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        return static::applyActivationDefaults($data);
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    protected static function applyActivationDefaults(array $data): array
    {
        $isPaid = ($data['payment_status'] ?? null) === PaymentStatus::Paid->value
            || ($data['payment_status'] ?? null) === PaymentStatus::Paid;
        $isActive = ($data['access_status'] ?? null) === AccessStatus::Active->value
            || ($data['access_status'] ?? null) === AccessStatus::Active;

        if ($isPaid && $isActive) {
            if (empty($data['sale_price']) && ! empty($data['subject_id'])) {
                $subject = Subject::query()->find($data['subject_id']);
                $data['sale_price'] = $subject?->price ?? 0;
            }

            if (empty($data['paid_at'])) {
                $data['paid_at'] = now();
            }

            if (empty($data['activated_at'])) {
                $data['activated_at'] = now();
            }
        }

        if (empty($data['activated_by'])) {
            $data['activated_by'] = static::authUser()?->id;
        }

        return $data;
    }
}
