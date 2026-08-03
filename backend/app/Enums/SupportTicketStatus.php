<?php

namespace App\Enums;

enum SupportTicketStatus: string
{
    case Pending = 'pending';
    case Active = 'active';
    case Closed = 'closed';

    public function label(): string
    {
        return match ($this) {
            self::Pending => 'بانتظار القبول',
            self::Active => 'جارية',
            self::Closed => 'منتهية',
        };
    }

    public static function options(): array
    {
        return collect(self::cases())
            ->mapWithKeys(fn (self $case): array => [$case->value => $case->label()])
            ->all();
    }
}
