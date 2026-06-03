<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class DriverDocumentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return auth()->user()->role === 'driver';
    }

    public function rules(): array
    {
        return [
            'document_type' => 'required|in:ktp,sim,stnk,vehicle_photo,selfie_ktp',
            'document_url' => 'required|string|max:500',
            'document_number' => 'nullable|string|max:100',
        ];
    }
}
