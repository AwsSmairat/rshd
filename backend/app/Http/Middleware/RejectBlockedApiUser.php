<?php

namespace App\Http\Middleware;

use App\Enums\UserStatus;
use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RejectBlockedApiUser
{
    /**
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user instanceof User && $user->status === UserStatus::Blocked) {
            return response()->json([
                'success' => false,
                'message' => 'حسابك غير مفعّل حالياً. يرجى التواصل مع الإدارة.',
                'errors' => new \stdClass,
            ], 403);
        }

        return $next($request);
    }
}
