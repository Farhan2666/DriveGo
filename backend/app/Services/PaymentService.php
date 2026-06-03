<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\Payment;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Http;

class PaymentService
{
    const MIDTRANS_SANDBOX = 'https://app.sandbox.midtrans.com/snap/v1';
    const MIDTRANS_PRODUCTION = 'https://app.midtrans.com/snap/v1';

    public function createPayment(Booking $booking, string $method): Payment
    {
        $externalId = 'DRIVEGO-' . $booking->booking_code . '-' . Str::random(6);

        $payment = Payment::create([
            'booking_id' => $booking->id,
            'payment_method' => $method,
            'amount' => $booking->total_price,
            'status' => 'pending',
            'external_id' => $externalId,
        ]);

        return $payment;
    }

    public function chargeMidtrans(Payment $payment): array
    {
        $booking = $payment->booking;
        $isProduction = app()->environment('production');
        $baseUrl = $isProduction ? self::MIDTRANS_PRODUCTION : self::MIDTRANS_SANDBOX;

        $payload = [
            'transaction_details' => [
                'order_id' => $payment->external_id,
                'gross_amount' => (int) $payment->amount,
            ],
            'customer_details' => [
                'first_name' => $booking->customer->fullname,
                'phone' => $booking->customer->phone,
                'email' => $booking->customer->email,
            ],
            'item_details' => [
                [
                    'id' => $booking->booking_code,
                    'price' => (int) $payment->amount,
                    'quantity' => 1,
                    'name' => 'DriveGo - ' . $booking->pickup_location . ' ke ' . $booking->destination,
                ],
            ],
        ];

        $response = Http::withBasicAuth(config('services.midtrans.server_key'), '')
            ->post($baseUrl . '/transactions', $payload);

        if ($response->successful()) {
            $body = $response->json();
            $payment->update(['transaction_id' => $body['transaction_id'] ?? null]);
            return $body;
        }

        $payment->markFailed();
        throw new \Exception('Midtrans charge failed: ' . $response->body());
    }

    public function chargeDuitku(Payment $payment): array
    {
        // Integrasi Duitku
        return [];
    }

    public function handleCallback(array $data): Payment
    {
        $externalId = $data['order_id'] ?? $data['external_id'] ?? null;

        $payment = Payment::where('external_id', $externalId)->firstOrFail();

        $transactionStatus = $data['transaction_status'] ?? $data['status'] ?? '';

        match ($transactionStatus) {
            'settlement', 'success', 'capture' => $payment->markSuccess(
                $data['transaction_id'] ?? $externalId,
                $data['payment_type'] ?? $data['channel'] ?? 'unknown'
            ),
            'deny', 'cancel', 'expire', 'failure' => $payment->markFailed(),
            'refund', 'refund_partial' => $payment->markRefunded(),
            default => null,
        };

        return $payment;
    }
}
