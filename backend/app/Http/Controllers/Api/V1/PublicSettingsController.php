<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\PlatformSettingsService;
use Illuminate\Http\JsonResponse;

class PublicSettingsController extends Controller
{
    public function __invoke(PlatformSettingsService $settings): JsonResponse
    {
        $public = $settings->publicSettings();

        return response()->json([
            'data' => [
                'platform_name' => $public['platform_name'] ?? 'RSHD',
                'platform_subtitle' => $public['platform_subtitle'] ?? null,
                'support_email' => $public['support_email'] ?? null,
                'support_phone' => $public['support_phone'] ?? null,
                'currency' => $public['currency'] ?? $public['currency_code'] ?? 'JOD',
                'currency_symbol' => $public['currency_symbol'] ?? 'د.أ',
                'logo_url' => $public['logo_url'] ?? null,
                'default_language' => $public['default_language'] ?? 'ar',
                'assignment_max_file_size' => (int) ($public['assignment_max_file_size_mb'] ?? 10),
                'assignment_allowed_file_types' => $public['assignment_allowed_file_types'] ?? [],
                'student_registration_enabled' => (bool) ($public['student_self_registration_enabled'] ?? true),
                'payment_instructions' => $public['payment_instructions'] ?? $settings->stringValue('payment_instructions', '', 'payments'),
                'maintenance_mode' => $settings->isMaintenanceModeEnabled(),
                'maintenance_message' => $settings->maintenanceMessage(),
            ],
        ]);
    }
}
