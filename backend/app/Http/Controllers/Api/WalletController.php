<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Withdrawal;

class WalletController extends Controller
{
    public function show()
    {
        $wallet = auth()->user()->driver->wallet()->with('transactions' => fn($q) => $q->latest()->limit(50))->firstOrFail();
        return response()->json(['success' => true, 'data' => $wallet]);
    }

    public function withdraw()
    {
        $data = request()->validate([
            'amount' => 'required|numeric|min:50000',
            'bank_name' => 'required|string|max:100',
            'bank_account_number' => 'required|string|max:50',
            'bank_account_name' => 'required|string|max:100',
        ]);

        $driver = auth()->user()->driver;
        $wallet = $driver->wallet;

        if (!$wallet->canWithdraw($data['amount'])) {
            return response()->json([
                'success' => false,
                'message' => 'Saldo tidak mencukupi',
            ], 400);
        }

        $withdrawal = Withdrawal::create([
            'wallet_id' => $wallet->id,
            'driver_id' => $driver->id,
            'amount' => $data['amount'],
            'bank_name' => $data['bank_name'],
            'bank_account_number' => $data['bank_account_number'],
            'bank_account_name' => $data['bank_account_name'],
        ]);

        $wallet->deductBalance($data['amount'], 'withdrawal', 'Penarikan saldo #' . $withdrawal->id);

        return response()->json([
            'success' => true,
            'message' => 'Permintaan penarikan diproses',
            'data' => $withdrawal,
        ], 201);
    }

    public function withdrawalHistory()
    {
        $withdrawals = Withdrawal::where('driver_id', auth()->user()->driver->id)
            ->orderBy('created_at', 'desc')
            ->paginate(request('per_page', 20));

        return response()->json(['success' => true, 'data' => $withdrawals]);
    }

    public function earningsHistory()
    {
        $driver = auth()->user()->driver;
        $transactions = $driver->wallet->transactions()
            ->with('booking')
            ->orderBy('created_at', 'desc')
            ->paginate(request('per_page', 20));

        return response()->json(['success' => true, 'data' => $transactions]);
    }
}
