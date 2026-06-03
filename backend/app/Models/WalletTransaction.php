<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WalletTransaction extends Model
{
    const UPDATED_AT = null;

    protected $fillable = [
        'wallet_id', 'booking_id', 'type', 'amount',
        'balance_before', 'balance_after', 'description',
    ];

    public function wallet()
    {
        return $this->belongsTo(Wallet::class);
    }

    public function booking()
    {
        return $this->belongsTo(Booking::class);
    }
}
