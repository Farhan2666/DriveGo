<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'phone' => 'required|string|max:20',
            'otp_code' => 'sometimes|string|size:6',
            'password' => 'required_without:otp_code|string|min:6',
        ];
    }
}
