<?php

namespace App\Enums;

enum VideoStatus: string
{
    case Uploading = 'uploading';
    case Processing = 'processing';
    case Ready = 'ready';
    case Failed = 'failed';

    public function label(): string
    {
        return match ($this) {
            self::Uploading => 'جاري الرفع',
            self::Processing => 'قيد المعالجة',
            self::Ready => 'جاهز',
            self::Failed => 'فشل',
        };
    }

    public static function options(): array
    {
        return collect(self::cases())
            ->mapWithKeys(fn (self $case): array => [$case->value => $case->label()])
            ->all();
    }
}
