<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Voucher extends Model
{
    protected $fillable = [
        'code', 'title', 'description', 'voucher_type',
        'discount_type', 'discount_value', 'min_order', 'max_discount',
        'quota', 'used_count', 'is_active', 'starts_at', 'ends_at',
    ];

    protected $casts = [
        'is_active' => 'boolean', 'starts_at' => 'datetime', 'ends_at' => 'datetime',
    ];

    public function users()
    {
        return $this->belongsToMany(User::class, 'user_vouchers')
            ->withPivot('is_used', 'used_at', 'booking_id');
    }

    public function isValid(): bool
    {
        return $this->is_active
            && $this->starts_at->isPast()
            && $this->ends_at->isFuture()
            && ($this->quota === 0 || $this->used_count < $this->quota);
    }

    public function calculateDiscount(float $subtotal): float
    {
        $discount = $this->discount_type === 'percentage'
            ? $subtotal * ($this->discount_value / 100)
            : $this->discount_value;

        if ($this->max_discount) {
            $discount = min($discount, $this->max_discount);
        }

        return $discount;
    }
}
