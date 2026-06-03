<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\PaymentCallbackRequest;
use App\Models\Booking;
use App\Services\PaymentService;
use App\Services\NotificationService;

class PaymentController extends Controller
{
    public function __construct(
        private PaymentService $paymentService,
        private NotificationService $notif
    ) {}

    public function pay($bookingId)
    {
        $booking = Booking::where('customer_id', auth()->id())
            ->where('status', 'waiting_payment')
            ->findOrFail($bookingId);

        $method = request('payment_method', 'qris');
        $payment = $this->paymentService->createPayment($booking, $method);

        $redirectUrl = null;
        if (in_array($method, ['qris', 'ovo', 'dana', 'gopay'])) {
            $midtrans = $this->paymentService->chargeMidtrans($payment);
            $redirectUrl = $midtrans['redirect_url'] ?? null;
        }

        return response()->json([
            'success' => true,
            'message' => 'Pembayaran diproses',
            'data' => [
                'payment' => $payment,
                'redirect_url' => $redirectUrl,
            ],
        ]);
    }

    public function callback(PaymentCallbackRequest $request)
    {
        $payment = $this->paymentService->handleCallback($request->all());

        if ($payment->status === 'success') {
            $this->notif->send(
                $payment->booking->customer_id,
                'Pembayaran Berhasil',
                "Pembayaran booking {$payment->booking->booking_code} berhasil",
                'payment', 'booking', $payment->booking_id
            );

            $this->notif->send(
                $payment->booking->driver->user_id,
                'Pembayaran Diterima',
                "Pembayaran booking {$payment->booking->booking_code} telah diterima",
                'payment', 'booking', $payment->booking_id
            );
        }

        return response()->json(['success' => true]);
    }

    public function history()
    {
        $payments = auth()->user()->customerBookings()
            ->with('payment')->get()->pluck('payment')->filter();

        return response()->json(['success' => true, 'data' => $payments]);
    }
}
