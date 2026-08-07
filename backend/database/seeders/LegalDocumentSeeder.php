<?php

namespace Database\Seeders;

use App\Enums\LegalDocumentType;
use App\Models\LegalDocument;
use App\Services\LegalDocumentService;
use Illuminate\Database\Seeder;

class LegalDocumentSeeder extends Seeder
{
    public function run(): void
    {
        /** @var LegalDocumentService $service */
        $service = app(LegalDocumentService::class);

        $files = [
            LegalDocumentType::PrivacyPolicy->value => 'privacy_policy_ar_v1.json',
            LegalDocumentType::TermsAndConditions->value => 'terms_ar_v1.json',
        ];

        foreach ($files as $typeValue => $filename) {
            $path = database_path('data/legal/'.$filename);

            if (! is_file($path)) {
                $this->command?->warn("Missing seed file: {$filename}");

                continue;
            }

            /** @var array<string, mixed> $payload */
            $payload = json_decode(file_get_contents($path), true, 512, JSON_THROW_ON_ERROR);
            $type = LegalDocumentType::from($typeValue);

            $exists = LegalDocument::query()
                ->where('type', $type)
                ->where('language', $payload['language'] ?? 'ar')
                ->where('version', $payload['version'])
                ->exists();

            if ($exists) {
                continue;
            }

            $document = $service->createDraft([
                'type' => $type,
                'title' => $payload['title'],
                'subtitle' => $payload['subtitle'] ?? null,
                'summary' => $payload['summary'] ?? null,
                'sections' => $payload['sections'],
                'version' => $payload['version'],
                'language' => $payload['language'] ?? 'ar',
                'requires_acceptance' => (bool) ($payload['requires_acceptance'] ?? false),
            ]);

            $service->publish($document);
        }
    }
}
