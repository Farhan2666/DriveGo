<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TripTracking extends Model
{
    const UPDATED_AT = null;

    protected $fillable = [
        'booking_id', 'driver_id', 'lat', 'lng',
        'speed', 'heading', 'accuracy', 'recorded_at',
    ];

    protected $casts = [
        'recorded_at' => 'datetime',
    ];

    public function booking()
    {
        return $this->belongsTo(Booking::class);
    }

    public function driver()
    {
        return $this->belongsTo(Driver::class);
    }
}
