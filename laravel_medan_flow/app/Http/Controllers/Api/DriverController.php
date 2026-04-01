<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TripLocation;
use Illuminate\Http\Request;

class DriverController extends Controller
{
    public function getDashboardInsights()
    {
        // 1. Panggil fungsi internal WeatherController yang mengembalikan ARRAY
        $weatherData = app(WeatherController::class)->getWeatherData();

        // 2. LOGIKA TRAFIK DINAMIS
        // Menghitung rata-rata kecepatan angkot dalam 30 menit terakhir
        $avgSpeed = TripLocation::where('created_at', '>=', now()->subMinutes(30))
                                ->avg('speed') ?? 30;

        $congestionLevel = 'low';
        $trafficDesc = 'Lancar';

        if ($avgSpeed < 15) {
            $congestionLevel = 'high';
            $trafficDesc = 'Macet Parah';
        } elseif ($avgSpeed < 25) {
            $congestionLevel = 'medium';
            $trafficDesc = 'Padat Merayap';
        }

        // 3. KEPUTUSAN AI
        $isGoodToWork = true;
        $recommendation = $weatherData['description']; // Ambil saran dari data cuaca

        if ($congestionLevel == 'high') {
            $isGoodToWork = false;
            $recommendation = "Trafik Medan sedang sangat padat. Pertimbangkan istirahat sejenak.";
        }

        return response()->json([
            'weather' => [
                'temp' => $weatherData['temp'],
                'condition' => $weatherData['condition'],
            ],
            'traffic' => [
                'level' => $congestionLevel,
                'description' => "Trafik: $trafficDesc",
                'avg_speed' => round($avgSpeed) . " km/h"
            ],
            'is_good_to_work' => $isGoodToWork,
            'recommendation' => $recommendation
        ]);
    }
}
