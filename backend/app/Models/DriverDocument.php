<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DriverDocument extends Model
{
    protected $fillable = [
        'driver_id', 'document_type', 'document_url', 'document_number',
        'status', 'rejection_reason', 'verified_by', 'verified_at',
    ];

    protected $casts = ['verified_at' => 'datetime'];

    public function driver()
    {
        return $this->belongsTo(Driver::class);
    }

    public function verifier()
    {
        return $this->belongsTo(User::class, 'verified_by');
    }

    public function approve(int $adminId): void
    {
        $this->update(['status' => 'verified', 'verified_by' => $adminId, 'verified_at' => now()]);
        $this->checkAllDocumentsVerified();
    }

    public function reject(int $adminId, string $reason): void
    {
        $this->update([
            'status' => 'rejected',
            'rejection_reason' => $reason,
            'verified_by' => $adminId,
            'verified_at' => now(),
        ]);
    }

    private function checkAllDocumentsVerified(): void
    {
        $allVerified = DriverDocument::where('driver_id', $this->driver_id)
            ->where('status', '!=', 'verified')
            ->count() === 0;

        if ($allVerified) {
            $this->driver->update(['verification_status' => 'verified', 'is_verified' => true]);
        }
    }
}
