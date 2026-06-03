<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Tymon\JWTAuth\Contracts\JWTSubject;
use Illuminate\Database\Eloquent\SoftDeletes;

class User extends Authenticatable implements JWTSubject
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'fullname', 'phone', 'email', 'password_hash', 'role',
        'avatar_url', 'fcm_token', 'is_active', 'last_login_at',
    ];

    protected $hidden = ['password_hash'];
    protected $casts = ['is_active' => 'boolean', 'last_login_at' => 'datetime'];

    public function driver()
    {
        return $this->hasOne(Driver::class);
    }

    public function customerBookings()
    {
        return $this->hasMany(Booking::class, 'customer_id');
    }

    public function sentMessages()
    {
        return $this->hasMany(Message::class, 'sender_id');
    }

    public function receivedMessages()
    {
        return $this->hasMany(Message::class, 'receiver_id');
    }

    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }

    public function reviews()
    {
        return $this->hasMany(Review::class, 'customer_id');
    }

    public function favoriteDrivers()
    {
        return $this->hasMany(FavoriteDriver::class, 'customer_id');
    }

    public function vouchers()
    {
        return $this->belongsToMany(Voucher::class, 'user_vouchers')
            ->withPivot('is_used', 'used_at', 'booking_id');
    }

    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

    public function getJWTCustomClaims()
    {
        return ['role' => $this->role];
    }
}
