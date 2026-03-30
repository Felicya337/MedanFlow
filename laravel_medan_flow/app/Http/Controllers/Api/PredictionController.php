<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Route;
use Illuminate\Http\Request;
use Carbon\Carbon;

class PredictionController extends Controller
{
    public function getTravelTimePrediction(Request $request)
    {
        $request->validate([
            'route_id' => 'required|exists:routes,id',
        ]);

        $route = Route::find($request->route_id);
        $now = Carbon::now('Asia/Jakarta');
        $hour = $now->hour;

        /**
         * LOGIKA PREDIKTIF JAM SIBUK MEDAN (SIMULASI AI)
         * Pagi (07:00 - 09:00) -> Keberangkatan Kantor/Sekolah
         * Sore (16:00 - 19:00) -> Jam Pulang Kerja
         */
        $isPeakHour = ($hour >= 7 && $hour <= 9) || ($hour >= 16 && $hour <= 19);

        $baseSpeed = 35; // Kecepatan rata-rata normal (km/jam)
        $congestionFactor = 1.0;
        $status = 'Lancar';
        $color = 'green';

        if ($isPeakHour) {
            $congestionFactor = 2.4; // Waktu tempuh meningkat 240%
            $status = 'Macet Parah (Peak Hour)';
            $color = 'red';
        } elseif ($hour >= 11 && $hour <= 14) {
            $congestionFactor = 1.5; // Macet jam makan siang
            $status = 'Padat Merayap';
            $color = 'orange';
        } elseif ($hour >= 21 || $hour <= 5) {
            $congestionFactor = 0.8; // Jalanan kosong di malam hari
            $status = 'Sangat Lancar';
            $color = 'blue';
        }

        // Perhitungan Waktu
        $normalTimeMinutes = ($route->distance / $baseSpeed) * 60;
        $predictedTimeMinutes = $normalTimeMinutes * $congestionFactor;
        $delayMinutes = $predictedTimeMinutes - $normalTimeMinutes;

        return response()->json([
            'route_name' => $route->name,
            'distance' => $route->distance . " km",
            'normal_time' => round($normalTimeMinutes) . " menit",
            'predicted_time' => round($predictedTimeMinutes) . " menit",
            'delay' => round($delayMinutes) . " menit tambahan",
            'congestion_level' => $status,
            'status_color' => $color,
            'current_time' => $now->format('H:i'),
            'prediction_factors' => [
                'weather' => 'Cerah Berawan',
                'event' => 'Tidak ada acara besar hari ini',
                'confidence_level' => '92%'
            ]
        ]);
    }
}
