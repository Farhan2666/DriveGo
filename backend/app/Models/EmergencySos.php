<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EmergencySos extends Model
{
    protected $table = 'emergency_sos';

    const UPDATED_AT = null;

    protected $fillable = [
        'user_id', 'booking_id', 'lat', 'lng', 'status', 'resolved_at',
    ];

    protected $casts = [
        'lat' => 'float', 'lng' => 'float',
        'resolved_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function booking()
    {
        return $this->belongsTo(Booking::class);
    }

    public function resolve(): void
    {
        $this->update(['status' => 'resolved', 'resolved_at' => now()]);
    }
}
