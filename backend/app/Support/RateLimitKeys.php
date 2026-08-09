<?php

namespace App\Support;

use Illuminate\Http\Request;

class RateLimitKeys
{
    public static function forRequest(Request $request): string
    {
        $user = $request->user();

        if ($user !== null) {
            return 'user:'.$user->getAuthIdentifier();
        }

        return 'ip:'.$request->ip();
    }
}
