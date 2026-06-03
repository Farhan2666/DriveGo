<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FavoriteDriver extends Model
{
    const UPDATED_AT = null;

    protected $fillable = ['customer_id', 'driver_id'];

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function driver()
    {
        return $this->belongsTo(Driver::class);
    }
}
