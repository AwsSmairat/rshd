<?php

namespace App\Http\Middleware;

use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RefreshAuthenticatedUser
{
    public function handle(Request $request, Closure $next): Response
    {
        $authUser = $request->user();

        if ($authUser !== null) {
            $freshUser = User::query()->find($authUser->getAuthIdentifier());

            if ($freshUser !== null) {
                $request->setUserResolver(static fn () => $freshUser);
            }
        }

        return $next($request);
    }
}
