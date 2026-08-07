#!/usr/bin/env php
<?php

/**
 * One-time helper: extracts section arrays from Flutter legal content files
 * and writes database/data/legal/*.json seed files.
 */

declare(strict_types=1);

$root = dirname(__DIR__, 3);

function extractSections(string $dart, string $listName): array
{
    if (! preg_match('/static (?:const )?(?:final )?List<[^>]+> '.$listName.' = \[(.*)\];/s', $dart, $match)) {
        throw new RuntimeException("Could not find sections list: {$listName}");
    }

    $body = $match[1];
    preg_match_all(
        '/(?:PrivacyPolicySectionData|TermsSectionData)\(\s*id:\s*\'([^\']+)\',\s*title:\s*\'([^\']+)\',\s*icon:\s*Icons\.(\w+),/s',
        $body,
        $headers,
        PREG_SET_ORDER,
    );

    $sections = [];
    $parts = preg_split(
        '/(?:PrivacyPolicySectionData|TermsSectionData)\(/',
        $body,
    );
    array_shift($parts);

    foreach ($parts as $index => $part) {
        if (! isset($headers[$index])) {
            continue;
        }

        $section = [
            'id' => $headers[$index][1],
            'title' => $headers[$index][2],
            'icon' => snakeCaseIcon($headers[$index][3]),
            'paragraphs' => extractStringList($part, 'paragraphs'),
            'bullet_points' => extractStringList($part, 'bulletPoints'),
            'subsections' => extractSubsections($part),
        ];

        $sections[] = $section;
    }

    return $sections;
}

function snakeCaseIcon(string $icon): string
{
    return strtolower(preg_replace('/([a-z])([A-Z])/', '$1_$2', $icon));
}

function extractStringList(string $part, string $field): array
{
    if (! preg_match('/'.$field.':\s*\[(.*?)\],/s', $part, $match)) {
        return [];
    }

    preg_match_all("/'((?:\\\\'|[^'])*)'/s", $match[1], $strings);

    return array_map(
        fn (string $s): string => resolveConfig(str_replace("\\'", "'", $s)),
        $strings[1] ?? [],
    );
}

function extractSubsections(string $part): array
{
    if (! preg_match('/subsections:\s*\[(.*)\],/s', $part, $match)) {
        return [];
    }

    preg_match_all(
        '/(?:PrivacyPolicySubsection|TermsSubsection)\(\s*title:\s*\'([^\']+)\',\s*items:\s*\[(.*?)\],/s',
        $match[1],
        $subs,
        PREG_SET_ORDER,
    );

    $result = [];
    foreach ($subs as $sub) {
        preg_match_all("/'((?:\\\\'|[^'])*)'/s", $sub[2], $items);
        $result[] = [
            'title' => $sub[1],
            'items' => array_map(
                fn (string $s): string => resolveConfig(str_replace("\\'", "'", $s)),
                $items[1] ?? [],
            ),
        ];
    }

    return $result;
}

function resolveConfig(string $text): string
{
    $replacements = [
        '${PrivacyPolicyConfig.accountDeletionProcessingDays}' => '30',
        '${TermsAndConditionsConfig.maximumAllowedDevices}' => '1',
        '${TermsAndConditionsConfig.refundRequestPeriod}' => 'حسب السياسة المعتمدة من الإدارة',
        '${TermsAndConditionsConfig.refundProcessingPeriod}' => 'حسب طريقة الدفع والسياسة المعتمدة',
        '${TermsAndConditionsConfig.governingLaw}' => 'القوانين المعمول بها في الدولة التي تعتمدها الجهة المالكة للمنصة',
        '${TermsAndConditionsConfig.disputeJurisdiction}' => 'جهة الاختصاص القضائي المعتمدة في النسخة المعتمدة من الشروط',
        '${TermsAndConditionsConfig.companyCountry}' => '',
    ];

    return str_replace(array_keys($replacements), array_values($replacements), $text);
}

$privacyDart = file_get_contents($root.'/lib/features/legal/privacy/data/privacy_policy_content.dart');
$termsDart = file_get_contents($root.'/lib/features/legal/terms/data/terms_and_conditions_content.dart');

$outDir = dirname(__DIR__).'/data/legal';
if (! is_dir($outDir)) {
    mkdir($outDir, 0755, true);
}

$privacyDoc = [
    'type' => 'privacy_policy',
    'title' => 'سياسة الخصوصية',
    'subtitle' => 'تعرّف على كيفية جمع بياناتك واستخدامها وحمايتها',
    'version' => '1.0',
    'language' => 'ar',
    'requires_acceptance' => false,
    'sections' => extractSections($privacyDart, 'sections'),
];

$termsDoc = [
    'type' => 'terms_and_conditions',
    'title' => 'الشروط والأحكام',
    'subtitle' => 'يرجى قراءة شروط استخدام منصة RSHD بعناية',
    'version' => '1.0',
    'language' => 'ar',
    'requires_acceptance' => false,
    'sections' => extractSections($termsDart, 'sections'),
];

file_put_contents(
    $outDir.'/privacy_policy_ar_v1.json',
    json_encode($privacyDoc, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT),
);

file_put_contents(
    $outDir.'/terms_ar_v1.json',
    json_encode($termsDoc, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT),
);

echo 'Generated '.count($privacyDoc['sections'])." privacy sections\n";
echo 'Generated '.count($termsDoc['sections'])." terms sections\n";
