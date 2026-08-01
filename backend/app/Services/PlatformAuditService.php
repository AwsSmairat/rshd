<?php

namespace App\Services;

use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class PlatformAuditService
{
    public function __construct(
        protected PlatformSettingsService $settings,
    ) {}

    public function logAdmin(
        string $action,
        ?User $actor = null,
        ?string $description = null,
        ?Model $model = null,
    ): void {
        $this->log('admin', $action, $actor, $description, $model);
    }

    public function logInstructor(
        string $action,
        ?User $actor = null,
        ?string $description = null,
        ?Model $model = null,
    ): void {
        $this->log('instructor', $action, $actor, $description, $model);
    }

    public function logActivation(
        string $action,
        ?User $actor = null,
        ?string $description = null,
        ?Model $model = null,
    ): void {
        $this->log('activation', $action, $actor, $description, $model);
    }

    public function logFinancial(
        string $action,
        ?User $actor = null,
        ?string $description = null,
        ?Model $model = null,
    ): void {
        $this->log('financial', $action, $actor, $description, $model);
    }

    public function logDevice(
        string $action,
        ?User $actor = null,
        ?string $description = null,
        ?Model $model = null,
    ): void {
        $this->log('device', $action, $actor, $description, $model);
    }

    public function logAuth(
        string $action,
        ?User $actor = null,
        ?string $description = null,
        ?Model $model = null,
    ): void {
        $this->log('auth', $action, $actor, $description, $model);
    }

    public function logSettings(
        string $action,
        ?User $actor = null,
        ?string $description = null,
        ?Model $model = null,
    ): void {
        $this->log('settings', $action, $actor, $description, $model);
    }

    public function pruneExpired(): int
    {
        $days = max(7, $this->settings->integer('retention_days', 90, 'audit'));

        return AuditLog::query()
            ->where('created_at', '<', now()->subDays($days))
            ->delete();
    }

    protected function log(
        string $category,
        string $action,
        ?User $actor = null,
        ?string $description = null,
        ?Model $model = null,
    ): void {
        if (! $this->settings->enabled('audit_logging_enabled', 'audit')) {
            return;
        }

        $toggle = match ($category) {
            'admin' => 'log_admin_actions',
            'instructor' => 'log_instructor_actions',
            'activation' => 'log_activation_changes',
            'financial' => 'log_financial_changes',
            'device' => 'log_device_resets',
            'auth' => 'log_auth_events',
            'settings' => 'log_settings_changes',
            default => null,
        };

        if ($toggle !== null && ! $this->settings->enabled($toggle, 'audit')) {
            return;
        }

        AuditLog::query()->create([
            'user_id' => $actor?->id,
            'action' => $action,
            'model_type' => $model !== null ? $model::class : null,
            'model_id' => $model?->getKey(),
            'description' => $description,
        ]);
    }
}
