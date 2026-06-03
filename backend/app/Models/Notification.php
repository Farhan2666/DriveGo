<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    const UPDATED_AT = null;

    protected $fillable = [
        'user_id', 'title', 'content', 'notification_type',
        'reference_type', 'reference_id', 'is_read', 'read_at',
    ];

    protected $casts = ['is_read' => 'boolean', 'read_at' => 'datetime'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function markAsRead(): void
    {
        if (!$this->is_read) {
            $this->update(['is_read' => true, 'read_at' => now()]);
        }
    }

    public function scopeUnread($query, $userId)
    {
        return $query->where('user_id', $userId)->where('is_read', false);
    }
}
