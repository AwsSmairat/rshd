<?php

namespace App\Http\Middleware;

use App\Models\User;
use App\Services\PlatformSettingsService;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RejectUnverifiedApiUser
{
    /**
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user instanceof User || ! $user->isStudent()) {
            return $next($request);
        }

        if ($user->email_verified_at !== null) {
            return $next($request);
        }

        if (! app(PlatformSettingsService::class)->emailVerificationRequired()) {
            return $next($request);
        }

        return response()->json([
            'success' => false,
            'message' => 'يرجى تأكيد بريدك الإلكتروني قبل استخدام التطبيق.',
            'errors' => new \stdClass,
        ], 403);
    }
}
