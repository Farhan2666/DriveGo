<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\MapService;

class MapController extends Controller
{
    public function __construct(private MapService $map) {}

    public function geocode()
    {
        $data = request()->validate(['address' => 'required|string']);
        $result = $this->map->geocode($data['address']);

        if (!$result) {
            return response()->json(['success' => false, 'message' => 'Alamat tidak ditemukan'], 404);
        }

        return response()->json(['success' => true, 'data' => $result]);
    }

    public function distance()
    {
        $data = request()->validate([
            'origin_lat' => 'required|numeric',
            'origin_lng' => 'required|numeric',
            'dest_lat' => 'required|numeric',
            'dest_lng' => 'required|numeric',
        ]);

        $result = $this->map->calculateDistance(
            ['lat' => $data['origin_lat'], 'lng' => $data['origin_lng']],
            ['lat' => $data['dest_lat'], 'lng' => $data['dest_lng']]
        );

        if (!$result) {
            return response()->json(['success' => false, 'message' => 'Gagal menghitung jarak'], 500);
        }

        return response()->json(['success' => true, 'data' => $result]);
    }

    public function autocomplete()
    {
        $data = request()->validate(['input' => 'required|string|min:3']);
        $results = $this->map->getAutoComplete($data['input']);

        return response()->json(['success' => true, 'data' => $results]);
    }
}
