<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\RegisterRequest;
use App\Http\Requests\LoginRequest;
use App\Models\User;
use App\Models\Driver;
use App\Models\Wallet;
use App\Services\OtpService;
use Illuminate\Support\Facades\Hash;
use Tymon\JWTAuth\Facades\JWTAuth;

class AuthController extends Controller
{
    public function __construct(private OtpService $otpService) {}

    public function register(RegisterRequest $request)
    {
        $user = User::create([
            'fullname' => $request->fullname,
            'phone' => $request->phone,
            'email' => $request->email,
            'password_hash' => Hash::make($request->password),
            'role' => $request->role ?? 'customer',
        ]);

        if ($user->role === 'driver') {
            $driver = Driver::create(['user_id' => $user->id]);
            Wallet::create(['driver_id' => $driver->id]);
        }

        $token = JWTAuth::fromUser($user);

        return response()->json([
            'success' => true,
            'message' => 'Registrasi berhasil',
            'data' => ['user' => $user, 'token' => $token],
        ], 201);
    }

    public function sendOtp(LoginRequest $request)
    {
        $otp = $this->otpService->generate($request->phone);
        $this->otpService->send($request->phone, $otp->code);

        return response()->json([
            'success' => true,
            'message' => 'Kode OTP telah dikirim',
        ]);
    }

    public function loginOtp(LoginRequest $request)
    {
        $valid = $this->otpService->verify($request->phone, $request->otp_code);
        if (!$valid) {
            return response()->json([
                'success' => false,
                'message' => 'Kode OTP salah atau sudah kadaluarsa',
            ], 400);
        }

        $user = User::firstOrCreate(
            ['phone' => $request->phone],
            ['fullname' => 'User ' . $request->phone, 'role' => 'customer']
        );

        $user->update(['last_login_at' => now()]);
        $token = JWTAuth::fromUser($user);

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil',
            'data' => ['user' => $user, 'token' => $token],
        ]);
    }

    public function loginPassword(LoginRequest $request)
    {
        $user = User::where('phone', $request->phone)->first();

        if (!$user || !Hash::check($request->password, $user->password_hash)) {
            return response()->json([
                'success' => false,
                'message' => 'Nomor telepon atau password salah',
            ], 401);
        }

        $user->update(['last_login_at' => now()]);
        $token = JWTAuth::fromUser($user);

        return response()->json([
            'success' => true,
            'data' => ['user' => $user, 'token' => $token],
        ]);
    }

    public function logout()
    {
        JWTAuth::invalidate(JWTAuth::getToken());

        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil',
        ]);
    }

    public function me()
    {
        $user = auth()->user()->load('driver.vehicles', 'driver.wallet');
        return response()->json(['success' => true, 'data' => $user]);
    }

    public function refreshToken()
    {
        $token = JWTAuth::refresh(JWTAuth::getToken());
        return response()->json(['success' => true, 'data' => ['token' => $token]]);
    }

    public function updateFcmToken()
    {
        request()->validate(['fcm_token' => 'required|string']);
        auth()->user()->update(['fcm_token' => request('fcm_token')]);

        return response()->json(['success' => true, 'message' => 'FCM token diperbarui']);
    }

    public function updateProfile()
    {
        $data = request()->validate([
            'fullname' => 'sometimes|string|max:100',
            'email' => 'sometimes|email|max:100|unique:users,email,' . auth()->id(),
            'avatar_url' => 'sometimes|string|max:500',
        ]);

        auth()->user()->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Profil diperbarui',
            'data' => auth()->user()->fresh(),
        ]);
    }
}
