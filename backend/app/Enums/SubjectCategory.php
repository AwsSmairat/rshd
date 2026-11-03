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

    /** Study years a medicine subject can belong to, as value => label. */
    public static function studyYearOptions(): array
    {
        return [
            1 => 'السنة الأولى',
            2 => 'السنة الثانية',
            3 => 'السنة الثالثة',
            4 => 'السنة الرابعة',
            5 => 'السنة الخامسة',
            6 => 'السنة السادسة',
        ];
    }

    /** Only medicine subjects are split by study year. */
    public function hasStudyYears(): bool
    {
        return $this === self::Medicine;
    }

    public static function options(): array
    {
        return collect(self::cases())
            ->mapWithKeys(fn (self $case): array => [$case->value => $case->label()])
            ->all();
    }
}
