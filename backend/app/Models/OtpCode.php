<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OtpCode extends Model
{
    const UPDATED_AT = null;

    protected $fillable = ['phone', 'code', 'purpose', 'is_used', 'expires_at'];
    protected $casts = ['is_used' => 'boolean', 'expires_at' => 'datetime'];

    public function scopeValid($query, $phone, $code, $purpose)
    {
        return $query->where('phone', $phone)
            ->where('code', $code)
            ->where('purpose', $purpose)
            ->where('is_used', false)
            ->where('expires_at', '>', now());
    }

    public function markAsUsed(): void
    {
        $this->update(['is_used' => true]);
    }
}
