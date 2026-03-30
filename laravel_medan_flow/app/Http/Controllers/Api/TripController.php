<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Trip;
use App\Models\TripLocation;
use App\Models\Driver;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class TripController extends Controller
{
    public function startTrip(Request $request)
    {
        // 1. Ambil user yang sedang login
        $user = $request->user();

        // 2. Cari data driver yang terhubung dengan user ini
        $driver = Driver::where('user_id', $user->id)->first();

        // Jika user ini ternyata tidak punya profil di tabel 'drivers'
        if (!$driver) {
            return response()->json([
                'message' => 'Profil Driver tidak ditemukan. Pastikan Anda sudah terdaftar sebagai Driver.'
            ], 404);
        }

        // 3. Buat data Trip baru
        try {
            $trip = Trip::create([
                'driver_id' => $driver->id,
                'angkot_id' => $driver->angkot_id, // Ambil angkot yang biasa dia bawa
                'start_time' => now(),
                'status' => 'ongoing',
                'current_status' => 'green',
                'current_eta' => 0
            ]);

            return response()->json($trip);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Gagal membuat data perjalanan: ' . $e->getMessage()
            ], 500);
        }
    }

    public function updateLocation(Request $request, $id)
    {
        $request->validate([
            'latitude' => 'required',
            'longitude' => 'required',
            'speed' => 'nullable'
        ]);

        TripLocation::create([
            'trip_id' => $id,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'speed' => $request->speed ?? 0
        ]);

        return response()->json(['status' => 'success']);
    }

    public function getActiveTrips()
    {
        $trips = Trip::with(['angkot.route', 'driver.user'])
            ->where('status', 'ongoing')
            ->get();

        $data = $trips->map(function ($trip) {
            $latestLocation = TripLocation::where('trip_id', $trip->id)
                ->latest()
                ->first();

            return [
                'trip_id' => $trip->id,
                'angkot_number' => $trip->angkot->angkot_number,
                'route_name' => $trip->angkot->route->name,
                'driver_name' => $trip->driver->user->name,
                'latitude' => $latestLocation ? $latestLocation->latitude : 3.5952,
                'longitude' => $latestLocation ? $latestLocation->longitude : 98.6722,
                'speed' => $latestLocation ? $latestLocation->speed : 0,
                'eta_minutes' => rand(2, 15),
                'crowd_status' => 'Normal',
                'congestion' => $trip->current_status,
            ];
        });

        return response()->json($data);
    }
}
