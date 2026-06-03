<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class FileStorageService
{
    const ALLOWED_IMAGE_TYPES = ['jpg', 'jpeg', 'png', 'webp'];
    const MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB

    public function upload(UploadedFile $file, string $path = 'uploads'): string
    {
        $filename = uniqid() . '_' . time() . '.' . $file->getClientOriginalExtension();
        $filePath = $file->storeAs($path, $filename, 's3');
        return Storage::disk('s3')->url($filePath);
    }

    public function uploadBase64(string $base64, string $path = 'uploads'): string
    {
        $data = base64_decode($base64);
        $extension = 'jpg';
        $filename = uniqid() . '_' . time() . '.' . $extension;

        Storage::disk('s3')->put($path . '/' . $filename, $data);
        return Storage::disk('s3')->url($path . '/' . $filename);
    }

    public function delete(string $url): bool
    {
        $path = parse_url($url, PHP_URL_PATH);
        if ($path && Storage::disk('s3')->exists(ltrim($path, '/'))) {
            return Storage::disk('s3')->delete(ltrim($path, '/'));
        }
        return false;
    }
}
