<?php

namespace App\Enums;

enum GradeSourceType: string
{
    case Assignment = 'assignment';
    case Quiz = 'quiz';
    case Manual = 'manual';

    public function label(): string
    {
        return match ($this) {
            self::Assignment => 'واجب',
            self::Quiz => 'اختبار',
            self::Manual => 'يدوي',
        };
    }

    public static function options(): array
    {
        return collect(self::cases())
            ->mapWithKeys(fn (self $case): array => [$case->value => $case->label()])
            ->all();
    }
}
