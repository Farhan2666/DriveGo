<?php

namespace App\Http\Middleware;

use Closure;

class RoleMiddleware
{
    public function handle($request, Closure $next, ...$roles)
    {
        $user = auth()->user();

        if (!$user) {
            return response()->json(['error' => 'Unauthenticated'], 401);
        }

        if (!in_array($user->role, $roles)) {
            return response()->json(['error' => 'Forbidden: tidak punya akses'], 403);
        }

        return $next($request);
    }
}
