<?php

namespace App\Enums;

enum AnnouncementType: string
{
    case General = 'general';
    case Subject = 'subject';
    case Important = 'important';

    public function label(): string
    {
        return match ($this) {
            self::General => 'إعلان عام',
            self::Subject => 'إعلان مادة',
            self::Important => 'مهم',
        };
    }

    public static function options(): array
    {
        return collect(self::cases())
            ->mapWithKeys(fn (self $case): array => [$case->value => $case->label()])
            ->all();
    }
}
