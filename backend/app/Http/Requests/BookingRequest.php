<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class BookingRequest extends FormRequest
{
    public function authorize(): bool
    {
        return auth()->user()->role === 'customer';
    }

    public function rules(): array
    {
        return [
            'driver_id' => 'required_without:vehicle_id|exists:drivers,id',
            'vehicle_id' => 'required_without:driver_id|exists:vehicles,id',
            'pickup_location' => 'required|string|max:500',
            'pickup_lat' => 'required|numeric',
            'pickup_lng' => 'required|numeric',
            'destination' => 'required|string|max:500',
            'dest_lat' => 'required|numeric',
            'dest_lng' => 'required|numeric',
            'booking_date' => 'required|date|after_or_equal:today',
            'booking_time' => 'required|date_format:H:i',
            'voucher_code' => 'nullable|string|exists:vouchers,code',
        ];
    }
}
