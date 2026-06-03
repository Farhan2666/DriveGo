<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Review extends Model
{
    const UPDATED_AT = null;

    protected $fillable = ['booking_id', 'customer_id', 'driver_id', 'rating', 'comment'];

    public function booking()
    {
        return $this->belongsTo(Booking::class);
    }

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function driver()
    {
        return $this->belongsTo(Driver::class);
    }
}
