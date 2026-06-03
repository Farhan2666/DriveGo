<?php

namespace App\Http\Middleware;

use Closure;
use Tymon\JWTAuth\Facades\JWTAuth;
use Tymon\JWTAuth\Exceptions\JWTException;

class JwtMiddleware
{
    public function handle($request, Closure $next)
    {
        try {
            $user = JWTAuth::parseToken()->authenticate();
        } catch (JWTException $e) {
            if ($e instanceof \Tymon\JWTAuth\Exceptions\TokenExpiredException) {
                try {
                    $newToken = JWTAuth::parseToken()->refresh();
                    $request->headers->set('Authorization', 'Bearer ' . $newToken);
                    $user = JWTAuth::setToken($newToken)->authenticate();
                } catch (\Exception $ex) {
                    return response()->json(['error' => 'Token expired, login lagi'], 401);
                }
            } else {
                return response()->json(['error' => 'Token tidak valid'], 401);
            }
        }

        return $next($request);
    }
}
