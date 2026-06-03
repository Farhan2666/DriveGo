<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Wallet extends Model
{
    protected $fillable = ['driver_id', 'balance', 'pending_balance', 'lifetime_earnings'];

    public function driver()
    {
        return $this->belongsTo(Driver::class);
    }

    public function transactions()
    {
        return $this->hasMany(WalletTransaction::class);
    }

    public function withdrawals()
    {
        return $this->hasMany(Withdrawal::class);
    }

    public function addBalance(float $amount, string $type, ?Booking $booking = null, string $description = ''): WalletTransaction
    {
        $balanceBefore = $this->balance;
        $this->increment('balance', $amount);
        $this->increment('lifetime_earnings', $amount);

        return $this->transactions()->create([
            'booking_id' => $booking?->id,
            'type' => $type,
            'amount' => $amount,
            'balance_before' => $balanceBefore,
            'balance_after' => $this->fresh()->balance,
            'description' => $description,
        ]);
    }

    public function deductBalance(float $amount, string $type, string $description = ''): WalletTransaction
    {
        $balanceBefore = $this->balance;
        $this->decrement('balance', $amount);

        return $this->transactions()->create([
            'type' => $type,
            'amount' => -$amount,
            'balance_before' => $balanceBefore,
            'balance_after' => $this->fresh()->balance,
            'description' => $description,
        ]);
    }

    public function canWithdraw(float $amount): bool
    {
        return $this->balance >= $amount;
    }
}
