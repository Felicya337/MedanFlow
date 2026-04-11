<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TripLocation;
use App\Models\UserReport;
use Illuminate\Http\Request;
use Carbon\Carbon;

class TrafficMapController extends Controller
{
    public function getPredictiveHeatmap(Request $request)
    {
        $now = Carbon::now();

        // 1. Data GPS Driver 10 Menit terakhir
        $driverData = TripLocation::where('created_at', '>=', $now->subMinutes(10))
            ->select('latitude', 'longitude', 'speed')->get()
            ->map(fn($loc) => [
                'lat' => (float)$loc->latitude,
                'lng' => (float)$loc->longitude,
                'level' => $loc->speed < 15 ? 'macet' : ($loc->speed < 25 ? 'padat' : 'lancar'),
                'radius' => 60
            ]);

        // 2. Laporan Insiden Warga
        $incidents = UserReport::where('expires_at', '>', Carbon::now())->get();

        return response()->json([
            'heatmap' => $driverData,
            'incidents' => $incidents
        ]);
    }
}
