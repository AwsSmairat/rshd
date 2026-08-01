<?php

namespace App\Enums;

enum AnnouncementTargetType: string
{
    case All = 'all';
    case Subject = 'subject';
    case Student = 'student';

    public function label(): string
    {
        return match ($this) {
            self::All => 'الجميع',
            self::Subject => 'المادة',
            self::Student => 'طالب',
        };
    }

    /**
     * @return array<string, string>
     */
    public static function formOptions(): array
    {
        return [
            self::All->value => self::All->label(),
            self::Subject->value => self::Subject->label(),
        ];
    }
}
