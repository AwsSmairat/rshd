<?php

namespace App\Enums;

enum AccessStatus: string
{
    case Active = 'active';
    case Pending = 'pending';
    case Revoked = 'revoked';
    case Expired = 'expired';

    public function label(): string
    {
        return match ($this) {
            self::Pending => 'بانتظار التفعيل',
            self::Active => 'مفعّل',
            self::Revoked => 'ملغى',
            self::Expired => 'منتهي',
        };
    }

    public static function options(): array
    {
        return collect(self::cases())
            ->mapWithKeys(fn (self $case): array => [$case->value => $case->label()])
            ->all();
    }
}
