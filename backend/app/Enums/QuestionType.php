<?php

namespace App\Enums;

enum QuestionType: string
{
    case Mcq = 'mcq';
    case TrueFalse = 'true_false';

    public function label(): string
    {
        return match ($this) {
            self::Mcq => 'اختيار من متعدد',
            self::TrueFalse => 'صح / خطأ',
        };
    }

    public static function options(): array
    {
        return collect(self::cases())
            ->mapWithKeys(fn (self $case): array => [$case->value => $case->label()])
            ->all();
    }
}
