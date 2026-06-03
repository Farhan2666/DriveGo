<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    const UPDATED_AT = null;

    protected $fillable = [
        'booking_id', 'sender_id', 'receiver_id', 'message',
        'message_type', 'attachment_url', 'is_read', 'read_at',
    ];

    protected $casts = ['is_read' => 'boolean', 'read_at' => 'datetime'];

    public function booking()
    {
        return $this->belongsTo(Booking::class);
    }

    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    public function receiver()
    {
        return $this->belongsTo(User::class, 'receiver_id');
    }

    public function markAsRead(): void
    {
        if (!$this->is_read) {
            $this->update(['is_read' => true, 'read_at' => now()]);
        }
    }

    public function scopeUnread($query, $userId)
    {
        return $query->where('receiver_id', $userId)->where('is_read', false);
    }
}
