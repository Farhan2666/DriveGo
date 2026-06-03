<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Voucher;

class VoucherController extends Controller
{
    public function index()
    {
        $vouchers = Voucher::where('is_active', true)
            ->where('starts_at', '<=', now())
            ->where('ends_at', '>=', now())
            ->where(function ($q) {
                $q->where('quota', 0)->orWhereColumn('used_count', '<', 'quota');
            })
            ->get(['id', 'code', 'title', 'description', 'voucher_type',
                   'discount_type', 'discount_value', 'min_order', 'max_discount', 'ends_at']);

        return response()->json(['success' => true, 'data' => $vouchers]);
    }

    public function validate()
    {
        $data = request()->validate([
            'code' => 'required|string|exists:vouchers,code',
            'total_price' => 'required|numeric|min:0',
        ]);

        $voucher = Voucher::where('code', $data['code'])->first();

        if (!$voucher->isValid()) {
            return response()->json([
                'success' => false,
                'message' => 'Voucher sudah tidak berlaku',
            ], 400);
        }

        if ($data['total_price'] < $voucher->min_order) {
            return response()->json([
                'success' => false,
                'message' => "Minimal pembelian Rp " . number_format($voucher->min_order, 0, ',', '.'),
            ], 400);
        }

        $discount = $voucher->calculateDiscount($data['total_price']);

        return response()->json([
            'success' => true,
            'data' => [
                'voucher' => $voucher,
                'discount' => $discount,
                'total_after_discount' => $data['total_price'] - $discount,
            ],
        ]);
    }
}
