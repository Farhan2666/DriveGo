<?php

namespace App\Services;

use App\Models\OtpCode;
use Illuminate\Support\Facades\Http;

class OtpService
{
    const OTP_LENGTH = 6;
    const OTP_EXPIRY_MINUTES = 5;
    const RESEND_COOLDOWN_SECONDS = 60;

    public function generate(string $phone, string $purpose = 'login'): OtpCode
    {
        OtpCode::where('phone', $phone)->where('purpose', $purpose)->where('is_used', false)
            ->where('expires_at', '<', now())->update(['is_used' => true]);

        $code = str_pad(random_int(0, 999999), self::OTP_LENGTH, '0', STR_PAD_LEFT);

        return OtpCode::create([
            'phone' => $phone,
            'code' => $code,
            'purpose' => $purpose,
            'expires_at' => now()->addMinutes(self::OTP_EXPIRY_MINUTES),
        ]);
    }

    public function verify(string $phone, string $code, string $purpose = 'login'): bool
    {
        $otp = OtpCode::valid($phone, $code, $purpose)->first();
        if (!$otp) return false;

        $otp->markAsUsed();
        return true;
    }

    public function send(string $phone, string $code): bool
    {
        // Integrate with WhatsApp / SMS gateway (e.g., Twilio, Vonage, Wablas)
        // Contoh dengan Wablas:
        // Http::post('https://pati.wablas.com/api/send-message', [
        //     'phone' => $phone,
        //     'message' => "Kode OTP DriveGo Anda: $code\n\nBerlaku 5 menit.",
        // ]);

        \Log::info("OTP sent to {$phone}: {$code}");
        return true;
    }
}
