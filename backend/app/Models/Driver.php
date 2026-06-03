<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Driver extends Model
{
    protected $fillable = [
        'user_id', 'rating', 'total_reviews', 'total_orders', 'total_earnings',
        'is_verified', 'verification_status', 'availability_status',
        'is_premium', 'premium_expires_at', 'bio', 'lat', 'lng',
    ];

    protected $casts = [
        'rating' => 'float', 'is_verified' => 'boolean', 'is_premium' => 'boolean',
        'premium_expires_at' => 'datetime', 'last_location_updated' => 'datetime',
        'lat' => 'float', 'lng' => 'float',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function vehicles()
    {
        return $this->hasMany(Vehicle::class);
    }

    public function bookings()
    {
        return $this->hasMany(Booking::class);
    }

    public function wallet()
    {
        return $this->hasOne(Wallet::class);
    }

    public function documents()
    {
        return $this->hasMany(DriverDocument::class);
    }

    public function reviews()
    {
        return $this->hasMany(Review::class);
    }

    public function subscription()
    {
        return $this->hasOne(DriverSubscription::class)->where('is_active', true);
    }

    public function isPremium(): bool
    {
        return $this->is_premium && $this->premium_expires_at && $this->premium_expires_at->isFuture();
    }

    public function scopeVerified($query)
    {
        return $query->where('is_verified', true);
    }

    public function scopeAvailable($query)
    {
        return $query->where('availability_status', 'available');
    }

    public function scopeNearby($query, $lat, $lng, $radiusKm = 10)
    {
        $latDelta = $radiusKm / 111.32;
        $lngDelta = $radiusKm / (111.32 * cos(deg2rad($lat)));
        return $query->whereBetween('lat', [$lat - $latDelta, $lat + $latDelta])
            ->whereBetween('lng', [$lng - $lngDelta, $lng + $lngDelta]);
    }

    public function updateRating(): void
    {
        $this->rating = $this->reviews()->avg('rating') ?? 0;
        $this->total_reviews = $this->reviews()->count();
        $this->save();
    }

    public function updateLocation(float $lat, float $lng): void
    {
        $this->update(['lat' => $lat, 'lng' => $lng, 'last_location_updated' => now()]);
    }
}
