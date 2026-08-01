<?php

namespace App\Enums;

enum SubjectCategory: string
{
    case Medicine = 'medicine';
    case It = 'it';
    case Engineering = 'engineering';
    case General = 'general';

    public function label(): string
    {
        return match ($this) {
            self::Medicine => 'طب',
            self::It => 'تقنية معلومات',
            self::Engineering => 'هندسة',
            self::General => 'عام',
        };
    }

    public static function options(): array
    {
        return collect(self::cases())
            ->mapWithKeys(fn (self $case): array => [$case->value => $case->label()])
            ->all();
    }
}
