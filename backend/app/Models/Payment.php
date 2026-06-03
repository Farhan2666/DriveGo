<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    protected $fillable = [
        'booking_id', 'payment_method', 'amount', 'status',
        'external_id', 'transaction_id', 'payment_channel',
        'payer_email', 'payer_phone', 'paid_at', 'refunded_at',
    ];

    protected $casts = [
        'paid_at' => 'datetime', 'refunded_at' => 'datetime',
    ];

    const METHODS = ['qris', 'ovo', 'dana', 'gopay', 'transfer_bank'];

    public function booking()
    {
        return $this->belongsTo(Booking::class);
    }

    public function markSuccess(string $transactionId, string $channel): void
    {
        $this->update([
            'status' => 'success',
            'transaction_id' => $transactionId,
            'payment_channel' => $channel,
            'paid_at' => now(),
        ]);
        $this->booking->update(['status' => 'paid']);
    }

    public function markFailed(): void
    {
        $this->update(['status' => 'failed']);
    }

    public function markRefunded(): void
    {
        $this->update(['status' => 'refunded', 'refunded_at' => now()]);
        $this->booking->update(['status' => 'refund']);
    }
}
