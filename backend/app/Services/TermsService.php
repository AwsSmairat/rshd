<?php

namespace App\Services;

use App\Enums\LegalDocumentType;
use App\Models\LegalDocument;
use App\Models\LegalDocumentAcceptance;
use App\Models\User;
use Illuminate\Http\Request;
use InvalidArgumentException;

class TermsService
{
    public function __construct(
        protected LegalDocumentService $legalDocuments,
        protected PlatformSettingsService $settings,
    ) {}

    public function currentDocument(?string $language = null): ?LegalDocument
    {
        return $this->legalDocuments->findPublished(
            LegalDocumentType::TermsAndConditions,
            $language ?? LegalDocumentService::DEFAULT_LANGUAGE,
        );
    }

    public function currentVersion(): string
    {
        return $this->currentDocument()?->version
            ?? (string) $this->settings->get('terms_current_version', '1.0', 'legal');
    }

    public function lastUpdated(): string
    {
        $document = $this->currentDocument();

        if ($document?->published_at) {
            return $document->published_at->format('Y/m/d');
        }

        return (string) $this->settings->get('terms_last_updated', '2026/07/31', 'legal');
    }

    public function userRequiresAcceptance(User $user): bool
    {
        if (! $user->isStudent()) {
            return false;
        }

        $document = $this->currentDocument();

        if (! $document || ! $document->requires_acceptance) {
            return false;
        }

        return $user->terms_accepted_version !== $document->version;
    }

    /**
     * @return array<string, mixed>
     */
    public function acceptanceStatus(User $user): array
    {
        $document = $this->currentDocument();
        $requiresAcceptance = $this->userRequiresAcceptance($user);

        return [
            'accepted' => ! $requiresAcceptance && $user->terms_accepted_version === $this->currentVersion(),
            'current_version' => $this->currentVersion(),
            'last_updated' => $this->lastUpdated(),
            'requires_acceptance' => $requiresAcceptance,
            'accepted_version' => $user->terms_accepted_version,
            'accepted_at' => $user->terms_accepted_at,
            'current_document_id' => $document?->id,
        ];
    }

    public function recordAcceptance(User $user, ?string $platform = null, ?Request $request = null): User
    {
        $document = $this->currentDocument();

        if (! $document) {
            throw new InvalidArgumentException('لا توجد شروط منشورة حاليًا.');
        }

        if (! $document->requires_acceptance && $user->terms_accepted_version === $document->version) {
            return $user;
        }

        if ($user->terms_accepted_version === $document->version) {
            return $user;
        }

        LegalDocumentAcceptance::create([
            'user_id' => $user->id,
            'legal_document_id' => $document->id,
            'version' => $document->version,
            'accepted_at' => now(),
            'ip_address' => $request?->ip(),
            'user_agent' => $request?->userAgent(),
            'platform' => $platform,
            'app_version' => $request?->header('X-App-Version'),
        ]);

        $user->update([
            'terms_accepted_version' => $document->version,
            'terms_accepted_at' => now(),
            'terms_accepted_platform' => $platform,
        ]);

        return $user->fresh();
    }
}
