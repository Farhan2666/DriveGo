<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'fullname' => 'required|string|max:100',
            'phone' => 'required|string|max:20|unique:users,phone',
            'email' => 'nullable|email|max:100|unique:users,email',
            'password' => 'required|string|min:6',
            'role' => 'sometimes|in:customer,driver',
        ];
    }

    public function messages(): array
    {
        return [
            'fullname.required' => 'Nama lengkap harus diisi',
            'phone.required' => 'Nomor telepon harus diisi',
            'phone.unique' => 'Nomor telepon sudah terdaftar',
            'password.min' => 'Password minimal 6 karakter',
        ];
    }
}
