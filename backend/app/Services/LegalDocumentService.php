<?php

namespace App\Services;

use App\Enums\LegalDocumentStatus;
use App\Enums\LegalDocumentType;
use App\Models\LegalDocument;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class LegalDocumentService
{
    public const DEFAULT_LANGUAGE = 'ar';

    public function cacheKey(LegalDocumentType $type, string $language = self::DEFAULT_LANGUAGE): string
    {
        return "legal_document:{$type->value}:{$language}";
    }

    public function findPublished(
        LegalDocumentType $type,
        string $language = self::DEFAULT_LANGUAGE,
    ): ?LegalDocument {
        return Cache::remember(
            $this->cacheKey($type, $language),
            now()->addHour(),
            fn (): ?LegalDocument => LegalDocument::query()
                ->where('type', $type)
                ->where('language', $language)
                ->where('status', LegalDocumentStatus::Published)
                ->orderByDesc('published_at')
                ->first(),
        );
    }

    public function forgetCache(LegalDocumentType $type, string $language = self::DEFAULT_LANGUAGE): void
    {
        Cache::forget($this->cacheKey($type, $language));
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function createDraft(array $payload, ?int $createdBy = null): LegalDocument
    {
        $this->validateSections($payload['sections'] ?? []);

        return LegalDocument::create([
            'type' => $payload['type'],
            'title' => $payload['title'],
            'subtitle' => $payload['subtitle'] ?? null,
            'summary' => $payload['summary'] ?? null,
            'sections' => $this->sanitizeSections($payload['sections']),
            'version' => $payload['version'],
            'language' => $payload['language'] ?? self::DEFAULT_LANGUAGE,
            'status' => LegalDocumentStatus::Draft,
            'requires_acceptance' => (bool) ($payload['requires_acceptance'] ?? false),
            'effective_at' => $payload['effective_at'] ?? null,
            'created_by' => $createdBy,
        ]);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function updateDraft(LegalDocument $document, array $payload): LegalDocument
    {
        if (! $document->isDraft()) {
            throw new InvalidArgumentException('لا يمكن تعديل وثيقة منشورة. أنشئ مسودة جديدة.');
        }

        if (isset($payload['sections'])) {
            $this->validateSections($payload['sections']);
            $payload['sections'] = $this->sanitizeSections($payload['sections']);
        }

        $document->update($payload);

        return $document->fresh();
    }

    public function publish(LegalDocument $document): LegalDocument
    {
        if (! $document->isDraft()) {
            throw new InvalidArgumentException('يمكن نشر المسودات فقط.');
        }

        return DB::transaction(function () use ($document): LegalDocument {
            LegalDocument::query()
                ->where('type', $document->type)
                ->where('language', $document->language)
                ->where('status', LegalDocumentStatus::Published)
                ->update(['status' => LegalDocumentStatus::Superseded]);

            $document->update([
                'status' => LegalDocumentStatus::Published,
                'published_at' => now(),
                'effective_at' => $document->effective_at ?? now(),
            ]);

            $this->forgetCache($document->type, $document->language);
            $this->syncLegacyTermsSettings($document);

            return $document->fresh();
        });
    }

    public function canDelete(LegalDocument $document): bool
    {
        return ! $document->hasAcceptances();
    }

    /**
     * @return array<string, mixed>
     */
    public function toPublicPayload(LegalDocument $document): array
    {
        return [
            'type' => $document->type->value,
            'title' => $document->title,
            'subtitle' => $document->subtitle,
            'summary' => $document->summary,
            'version' => $document->version,
            'language' => $document->language,
            'last_updated' => $document->published_at?->toIso8601String(),
            'effective_at' => $document->effective_at?->toIso8601String(),
            'requires_acceptance' => $document->requires_acceptance,
            'sections' => $document->sections,
        ];
    }

    /**
     * @param  array<int, array<string, mixed>>  $sections
     */
    public function validateSections(array $sections): void
    {
        if ($sections === []) {
            throw new InvalidArgumentException('يجب إضافة قسم واحد على الأقل.');
        }

        foreach ($sections as $index => $section) {
            if (empty($section['id']) || empty($section['title'])) {
                throw new InvalidArgumentException("القسم رقم {$index} يحتاج معرفًا وعنوانًا.");
            }
        }
    }

    /**
     * @param  array<int, array<string, mixed>>  $sections
     * @return array<int, array<string, mixed>>
     */
    public function sanitizeSections(array $sections): array
    {
        return array_map(function (array $section): array {
            return [
                'id' => strip_tags((string) $section['id']),
                'title' => strip_tags((string) $section['title']),
                'icon' => strip_tags((string) ($section['icon'] ?? 'article_outlined')),
                'paragraphs' => $this->sanitizeStringList($section['paragraphs'] ?? []),
                'bullet_points' => $this->sanitizeStringList($section['bullet_points'] ?? []),
                'subsections' => array_map(
                    fn (array $sub): array => [
                        'title' => strip_tags((string) ($sub['title'] ?? '')),
                        'items' => $this->sanitizeStringList($sub['items'] ?? []),
                    ],
                    $section['subsections'] ?? [],
                ),
            ];
        }, $sections);
    }

    /**
     * @param  array<int, mixed>  $values
     * @return array<int, string>
     */
    protected function sanitizeStringList(array $values): array
    {
        return array_values(array_filter(array_map(
            fn ($value): string => trim(strip_tags((string) $value)),
            $values,
        )));
    }

    protected function syncLegacyTermsSettings(LegalDocument $document): void
    {
        if ($document->type !== LegalDocumentType::TermsAndConditions) {
            return;
        }

        /** @var PlatformSettingsService $settings */
        $settings = app(PlatformSettingsService::class);

        $settings->set('terms_current_version', $document->version, 'legal');
        $settings->set(
            'terms_last_updated',
            $document->published_at?->format('Y/m/d') ?? now()->format('Y/m/d'),
            'legal',
        );
        $settings->set(
            'terms_requires_reacceptance',
            $document->requires_acceptance,
            'legal',
        );
    }
}
