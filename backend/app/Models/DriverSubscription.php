<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DriverSubscription extends Model
{
    protected $fillable = [
        'driver_id', 'subscription_type', 'amount',
        'starts_at', 'ends_at', 'is_active', 'payment_id',
    ];

    protected $casts = [
        'starts_at' => 'datetime', 'ends_at' => 'datetime',
        'is_active' => 'boolean',
    ];

    public function driver()
    {
        return $this->belongsTo(Driver::class);
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true)
            ->where('ends_at', '>', now());
    }
}
