<?php

namespace App\Enums;

enum LegalDocumentType: string
{
    case PrivacyPolicy = 'privacy_policy';
    case TermsAndConditions = 'terms_and_conditions';

    public function label(): string
    {
        return match ($this) {
            self::PrivacyPolicy => 'سياسة الخصوصية',
            self::TermsAndConditions => 'الشروط والأحكام',
        };
    }

    public static function options(): array
    {
        return collect(self::cases())
            ->mapWithKeys(fn (self $case): array => [$case->value => $case->label()])
            ->all();
    }
}
