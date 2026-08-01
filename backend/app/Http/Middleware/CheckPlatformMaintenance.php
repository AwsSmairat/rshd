<?php

namespace App\Http\Middleware;

use App\Services\PlatformSettingsService;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckPlatformMaintenance
{
    public function __construct(
        protected PlatformSettingsService $settings,
    ) {}

    /**
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        if (! $this->settings->isMaintenanceModeEnabled()) {
            return $next($request);
        }

        if ($request->is('api/*')) {
            return $this->handleApi($request, $next);
        }

        if ($request->is('admin', 'admin/*')) {
            return $this->handleAdminPanel($request, $next);
        }

        return $next($request);
    }

    protected function handleApi(Request $request, Closure $next): Response
    {
        if ($request->is('api/v1/settings/public')) {
            return $next($request);
        }

        return response()->json([
            'success' => false,
            'message' => $this->settings->maintenanceMessage(),
            'maintenance' => true,
            'errors' => new \stdClass,
        ], 503);
    }

    protected function handleAdminPanel(Request $request, Closure $next): Response
    {
        if ($this->allowsAdminPanelAccess($request)) {
            return $next($request);
        }

        if ($request->expectsJson() || $request->header('X-Livewire')) {
            return response()->json([
                'message' => $this->settings->maintenanceMessage(),
                'maintenance' => true,
            ], 503);
        }

        return response()->view('maintenance', [
            'message' => $this->settings->maintenanceMessage(),
        ], 503);
    }

    protected function allowsAdminPanelAccess(Request $request): bool
    {
        if ($request->is(
            'admin/login',
            'admin/logout',
            'admin/password-reset/*',
            'admin/forgot-password',
        )) {
            return true;
        }

        return $request->user()?->isAdmin() ?? false;
    }
}
