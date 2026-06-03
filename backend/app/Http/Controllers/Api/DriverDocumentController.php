<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\DriverDocumentRequest;
use App\Models\DriverDocument;

class DriverDocumentController extends Controller
{
    public function index()
    {
        $documents = DriverDocument::where('driver_id', auth()->user()->driver->id)->get();
        return response()->json(['success' => true, 'data' => $documents]);
    }

    public function store(DriverDocumentRequest $request)
    {
        $document = DriverDocument::create([
            'driver_id' => auth()->user()->driver->id,
            'document_type' => $request->document_type,
            'document_url' => $request->document_url,
            'document_number' => $request->document_number,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Dokumen berhasil diunggah',
            'data' => $document,
        ], 201);
    }

    public function destroy($id)
    {
        $document = DriverDocument::where('driver_id', auth()->user()->driver->id)->findOrFail($id);
        $document->delete();

        return response()->json(['success' => true, 'message' => 'Dokumen dihapus']);
    }
}
