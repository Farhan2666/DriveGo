<?php

namespace App\Services;

class PricingService
{
    const BASE_PRICE = 15000;
    const PRICE_PER_KM = 3500;
    const COMMISSION_RATE = 0.10;
    const MIN_SERVICE_FEE = 2000;
    const MAX_SERVICE_FEE = 10000;

    public function calculatePrice(float $distanceKm): array
    {
        $distancePrice = $distanceKm * self::PRICE_PER_KM;
        $basePrice = self::BASE_PRICE;
        $subtotal = $basePrice + $distancePrice;

        $serviceFee = min(max($subtotal * 0.05, self::MIN_SERVICE_FEE), self::MAX_SERVICE_FEE);
        $commissionAmount = $subtotal * self::COMMISSION_RATE;

        $totalPrice = $subtotal + $serviceFee + $commissionAmount;

        return [
            'base_price' => round($basePrice, 2),
            'distance_price' => round($distancePrice, 2),
            'service_fee' => round($serviceFee, 2),
            'commission_amount' => round($commissionAmount, 2),
            'total_price' => round($totalPrice, 2),
        ];
    }

    public function applyVoucher(float $totalPrice, ?string $voucherCode): array
    {
        if (!$voucherCode) {
            return ['total_price' => $totalPrice, 'voucher_discount' => 0];
        }

        $voucher = \App\Models\Voucher::where('code', $voucherCode)->first();
        if (!$voucher || !$voucher->isValid()) {
            throw new \Exception('Voucher tidak valid atau sudah habis masa berlaku.');
        }

        $discount = $voucher->calculateDiscount($totalPrice);
        $finalPrice = max(0, $totalPrice - $discount);

        return [
            'total_price' => $finalPrice,
            'voucher_discount' => $discount,
            'voucher_id' => $voucher->id,
        ];
    }
}
