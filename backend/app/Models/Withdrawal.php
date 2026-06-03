<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Withdrawal extends Model
{
    protected $fillable = [
        'wallet_id', 'driver_id', 'amount',
        'bank_name', 'bank_account_number', 'bank_account_name',
        'status', 'admin_note', 'processed_by', 'processed_at', 'completed_at',
    ];

    protected $casts = [
        'processed_at' => 'datetime', 'completed_at' => 'datetime',
    ];

    public function wallet()
    {
        return $this->belongsTo(Wallet::class);
    }

    public function driver()
    {
        return $this->belongsTo(Driver::class);
    }

    public function processor()
    {
        return $this->belongsTo(User::class, 'processed_by');
    }

    public function approve(int $adminId): void
    {
        $this->update([
            'status' => 'completed',
            'processed_by' => $adminId,
            'processed_at' => now(),
            'completed_at' => now(),
        ]);
    }

    public function reject(int $adminId, string $note): void
    {
        $this->update([
            'status' => 'rejected',
            'admin_note' => $note,
            'processed_by' => $adminId,
            'processed_at' => now(),
        ]);
        $this->wallet->addBalance($this->amount, 'adjustment', null, 'Pengembalian dana withdrawal ditolak');
    }
}
