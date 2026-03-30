<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Trip;
use App\Models\TripLocation;
use Illuminate\Http\Request;

class TripController extends Controller
{
    /**
     * Memulai perjalanan (Driver)
     */
    public function startTrip(Request $request)
    {
        $trip = Trip::create([
            'driver_id' => $request->user()->id,
            'angkot_id' => 1, // Simulasi angkot ID
            'start_time' => now(),
            'status' => 'ongoing',
            'current_status' => 'green'
        ]);
        return response()->json($trip);
    }

    /**
     * Update lokasi berkala (Driver)
     */
    public function updateLocation(Request $request, $id)
    {
        TripLocation::create([
            'trip_id' => $id,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'speed' => $request->speed
        ]);
        return response()->json(['status' => 'success']);
    }

    /**
     * Mendapatkan semua angkot aktif untuk Penumpang (Guest)
     */
    public function getActiveTrips()
    {
        // Ambil perjalanan yang sedang berlangsung
        $trips = Trip::with(['angkot.route', 'driver.user'])
            ->where('status', 'ongoing')
            ->get();

        $data = $trips->map(function ($trip) {
            // Ambil lokasi terbaru angkot ini
            $latestLocation = TripLocation::where('trip_id', $trip->id)
                ->latest()
                ->first();

            // Simulasi status kepadatan (Crowd Status)
            $crowdLevels = ['Sepi', 'Normal', 'Penuh'];

            return [
                'trip_id' => $trip->id,
                'angkot_number' => $trip->angkot->angkot_number,
                'route_name' => $trip->angkot->route->name,
                'driver_name' => $trip->driver->user->name,
                'latitude' => $latestLocation ? $latestLocation->latitude : 3.5952,
                'longitude' => $latestLocation ? $latestLocation->longitude : 98.6722,
                'speed' => $latestLocation ? $latestLocation->speed : 0,
                'eta_minutes' => rand(2, 15), // Simulasi ETA ke titik terdekat user
                'crowd_status' => $crowdLevels[rand(0, 2)],
                'congestion' => $trip->current_status, // green, yellow, red
            ];
        });

        return response()->json($data);
    }
}
