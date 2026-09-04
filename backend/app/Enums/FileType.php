<?php

namespace App\Enums;

enum FileType: string
{
    case Pdf = 'pdf';
    case Ppt = 'ppt';
    case Doc = 'doc';
    case Image = 'image';
    case Other = 'other';

    public function label(): string
    {
        return match ($this) {
            self::Pdf => 'PDF',
            self::Ppt => 'PowerPoint',
            self::Doc => 'Word',
            self::Image => 'صورة',
            self::Other => 'أخرى',
        };
    }

    public function needsPdfPreview(): bool
    {
        return $this === self::Doc || $this === self::Ppt;
    }

    public function isInAppViewable(): bool
    {
        return $this === self::Pdf || $this->needsPdfPreview() || $this === self::Image;
    }

    /**
     * @return array<string, string>
     */
    public static function options(): array
    {
        return collect(self::cases())
            ->mapWithKeys(fn (self $case): array => [$case->value => $case->label()])
            ->all();
    }
}
