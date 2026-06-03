<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class MapService
{
    const GOOGLE_MAPS_BASE = 'https://maps.googleapis.com/maps/api';

    public function geocode(string $address): ?array
    {
        $response = Http::get(self::GOOGLE_MAPS_BASE . '/geocode/json', [
            'address' => $address,
            'key' => config('services.google_maps.api_key'),
        ]);

        if ($response->successful() && $response->json('status') === 'OK') {
            $location = $response->json('results.0.geometry.location');
            return ['lat' => $location['lat'], 'lng' => $location['lng']];
        }

        return null;
    }

    public function reverseGeocode(float $lat, float $lng): ?string
    {
        $response = Http::get(self::GOOGLE_MAPS_BASE . '/geocode/json', [
            'latlng' => "{$lat},{$lng}",
            'key' => config('services.google_maps.api_key'),
        ]);

        if ($response->successful() && $response->json('status') === 'OK') {
            return $response->json('results.0.formatted_address');
        }

        return null;
    }

    public function calculateDistance(array $origin, array $destination): ?array
    {
        $originStr = "{$origin['lat']},{$origin['lng']}";
        $destStr = "{$destination['lat']},{$destination['lng']}";

        $response = Http::get(self::GOOGLE_MAPS_BASE . '/distancematrix/json', [
            'origins' => $originStr,
            'destinations' => $destStr,
            'key' => config('services.google_maps.api_key'),
            'mode' => 'driving',
        ]);

        if ($response->successful() && $response->json('status') === 'OK') {
            $element = $response->json('rows.0.elements.0');
            if ($element && $element['status'] === 'OK') {
                return [
                    'distance_km' => $element['distance']['value'] / 1000,
                    'duration_min' => $element['duration']['value'] / 60,
                ];
            }
        }

        return null;
    }

    public function getAutoComplete(string $input): array
    {
        $response = Http::get(self::GOOGLE_MAPS_BASE . '/place/autocomplete/json', [
            'input' => $input,
            'key' => config('services.google_maps.api_key'),
            'components' => 'country:id',
        ]);

        if ($response->successful()) {
            return $response->json('predictions', []);
        }

        return [];
    }
}
