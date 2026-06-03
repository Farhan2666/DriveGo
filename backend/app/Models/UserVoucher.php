<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserVoucher extends Model
{
    const UPDATED_AT = null;

    protected $fillable = ['user_id', 'voucher_id', 'is_used', 'used_at', 'booking_id'];
    protected $casts = ['is_used' => 'boolean', 'used_at' => 'datetime'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function voucher()
    {
        return $this->belongsTo(Voucher::class);
    }

    public function booking()
    {
        return $this->belongsTo(Booking::class);
    }
}
