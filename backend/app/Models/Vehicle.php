<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Vehicle extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'driver_id', 'plate_number', 'brand', 'model',
        'year', 'color', 'capacity', 'photo_url', 'is_active',
    ];

    protected $casts = ['year' => 'integer', 'is_active' => 'boolean'];

    public function driver()
    {
        return $this->belongsTo(Driver::class);
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }
}
