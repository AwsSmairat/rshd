<?php

namespace App\Services;

use App\Models\User;

class TermsService
{
    public function __construct(
        protected PlatformSettingsService $settings,
    ) {}

    public function currentVersion(): string
    {
        return (string) $this->settings->get('terms_current_version', '1.0', 'legal');
    }

    public function lastUpdated(): string
    {
        return (string) $this->settings->get('terms_last_updated', '2026/07/31', 'legal');
    }

    public function requiresReacceptanceEnabled(): bool
    {
        return (bool) $this->settings->get('terms_requires_reacceptance', false, 'legal');
    }

    public function userRequiresAcceptance(User $user): bool
    {
        if (! $user->isStudent()) {
            return false;
        }

        if (! $this->requiresReacceptanceEnabled()) {
            return false;
        }

        return $user->terms_accepted_version !== $this->currentVersion();
    }

    /**
     * @return array<string, mixed>
     */
    public function acceptanceStatus(User $user): array
    {
        return [
            'current_version' => $this->currentVersion(),
            'last_updated' => $this->lastUpdated(),
            'requires_acceptance' => $this->userRequiresAcceptance($user),
            'accepted_version' => $user->terms_accepted_version,
            'accepted_at' => $user->terms_accepted_at,
        ];
    }

    public function recordAcceptance(User $user, ?string $platform = null): User
    {
        $version = $this->currentVersion();

        if ($user->terms_accepted_version === $version) {
            return $user;
        }

        $user->update([
            'terms_accepted_version' => $version,
            'terms_accepted_at' => now(),
            'terms_accepted_platform' => $platform,
        ]);

        return $user->fresh();
    }
}
