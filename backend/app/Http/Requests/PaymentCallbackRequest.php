<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class PaymentCallbackRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'order_id' => 'nullable|string',
            'external_id' => 'nullable|string',
            'transaction_status' => 'nullable|string',
            'status' => 'nullable|string',
            'transaction_id' => 'nullable|string',
            'payment_type' => 'nullable|string',
            'channel' => 'nullable|string',
        ];
    }
}
