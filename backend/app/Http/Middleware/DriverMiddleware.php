<?php

namespace App\Http\Middleware;

use Closure;

class DriverMiddleware
{
    public function handle($request, Closure $next)
    {
        $user = auth()->user();
        if (!$user || $user->role !== 'driver') {
            return response()->json(['error' => 'Hanya untuk driver'], 403);
        }

        if (!$user->driver) {
            return response()->json(['error' => 'Profil driver belum lengkap'], 400);
        }

        if (!$user->driver->is_verified) {
            return response()->json(['error' => 'Akun driver belum terverifikasi'], 403);
        }

        $request->merge(['auth_driver' => $user->driver]);
        return $next($request);
    }
}
