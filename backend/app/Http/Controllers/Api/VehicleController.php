<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Vehicle;

class VehicleController extends Controller
{
    public function index()
    {
        $vehicles = Vehicle::active()
            ->with('driver.user')
            ->when(request('driver_id'), fn($q) => $q->where('driver_id', request('driver_id')))
            ->when(request('brand'), fn($q) => $q->where('brand', request('brand')))
            ->when(request('min_capacity'), fn($q) => $q->where('capacity', '>=', request('min_capacity')))
            ->paginate(request('per_page', 20));

        return response()->json(['success' => true, 'data' => $vehicles]);
    }

    public function show($id)
    {
        $vehicle = Vehicle::with('driver.user')->findOrFail($id);
        return response()->json(['success' => true, 'data' => $vehicle]);
    }

    public function store()
    {
        $data = request()->validate([
            'plate_number' => 'required|string|max:20|unique:vehicles',
            'brand' => 'required|string|max:50',
            'model' => 'required|string|max:100',
            'year' => 'required|integer|min:2000|max:' . (date('Y') + 1),
            'color' => 'required|string|max:30',
            'capacity' => 'required|integer|min:1|max:50',
        ]);

        $data['driver_id'] = auth()->user()->driver->id;
        $vehicle = Vehicle::create($data);

        return response()->json([
            'success' => true,
            'message' => 'Kendaraan ditambahkan',
            'data' => $vehicle,
        ], 201);
    }

    public function update($id)
    {
        $vehicle = Vehicle::where('driver_id', auth()->user()->driver->id)->findOrFail($id);

        $data = request()->validate([
            'plate_number' => 'sometimes|string|max:20|unique:vehicles,plate_number,' . $id,
            'brand' => 'sometimes|string|max:50',
            'model' => 'sometimes|string|max:100',
            'year' => 'sometimes|integer|min:2000|max:' . (date('Y') + 1),
            'color' => 'sometimes|string|max:30',
            'capacity' => 'sometimes|integer|min:1|max:50',
        ]);

        $vehicle->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Kendaraan diperbarui',
            'data' => $vehicle,
        ]);
    }

    public function destroy($id)
    {
        $vehicle = Vehicle::where('driver_id', auth()->user()->driver->id)->findOrFail($id);
        $vehicle->delete();

        return response()->json([
            'success' => true,
            'message' => 'Kendaraan dihapus',
        ]);
    }
}
