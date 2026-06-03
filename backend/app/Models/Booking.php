<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Booking extends Model
{
    protected $fillable = [
        'booking_code', 'customer_id', 'driver_id', 'vehicle_id',
        'pickup_location', 'pickup_lat', 'pickup_lng',
        'destination', 'dest_lat', 'dest_lng',
        'booking_date', 'booking_time', 'total_distance_km', 'estimated_duration_min',
        'base_price', 'distance_price', 'service_fee', 'commission_amount',
        'voucher_discount', 'total_price', 'status',
        'cancellation_reason', 'cancelled_by', 'cancelled_at',
        'started_at', 'completed_at', 'driver_rating', 'customer_review',
    ];

    protected $casts = [
        'booking_date' => 'date', 'booking_time' => 'string',
        'pickup_lat' => 'float', 'pickup_lng' => 'float',
        'dest_lat' => 'float', 'dest_lng' => 'float',
        'total_distance_km' => 'float', 'estimated_duration_min' => 'integer',
        'cancelled_at' => 'datetime', 'started_at' => 'datetime', 'completed_at' => 'datetime',
    ];

    const STATUS = [
        'waiting_payment', 'paid', 'driver_confirmed', 'driver_on_the_way',
        'customer_picked_up', 'trip_started', 'trip_completed', 'cancelled', 'refund',
    ];

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function driver()
    {
        return $this->belongsTo(Driver::class);
    }

    public function vehicle()
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function payment()
    {
        return $this->hasOne(Payment::class);
    }

    public function review()
    {
        return $this->hasOne(Review::class);
    }

    public function tracking()
    {
        return $this->hasMany(TripTracking::class);
    }

    public function messages()
    {
        return $this->hasMany(Message::class);
    }

    public function scopeActive($query)
    {
        return $query->whereNotIn('status', ['trip_completed', 'cancelled', 'refund']);
    }

    public function scopeByCustomer($query, $userId)
    {
        return $query->where('customer_id', $userId);
    }

    public function scopeByDriver($query, $driverId)
    {
        return $query->where('driver_id', $driverId);
    }

    public function canCancel(): bool
    {
        return in_array($this->status, ['waiting_payment', 'paid', 'driver_confirmed']);
    }

    public function cancel(string $reason, string $by): void
    {
        $this->update([
            'status' => 'cancelled',
            'cancellation_reason' => $reason,
            'cancelled_by' => $by,
            'cancelled_at' => now(),
        ]);
    }
}
