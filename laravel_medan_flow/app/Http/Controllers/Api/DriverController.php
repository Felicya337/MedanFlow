<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TripLocation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class DriverController extends Controller
{
    public function getDashboardInsights()
    {
        try {
            // 1. Ambil data cuaca (Array)
            $weatherData = app(WeatherController::class)->getWeatherData();

            // 2. LOGIKA TRAFIK DINAMIS
            $avgSpeed = TripLocation::where('created_at', '>=', now()->subMinutes(30))
                                    ->avg('speed') ?? 30;

            $congestionLevel = 'low';
            $trafficDesc = 'Lancar';
            $workScore = 100; // Skor dasar

            if ($avgSpeed < 15) {
                $congestionLevel = 'high';
                $trafficDesc = 'Macet Parah';
                $workScore -= 40;
            } elseif ($avgSpeed < 25) {
                $congestionLevel = 'medium';
                $trafficDesc = 'Padat Merayap';
                $workScore -= 15;
            }

            // Kurangi skor jika hujan (icon dari weatherData)
            if ($weatherData['icon'] === 'rainy') {
                $workScore -= 20;
            }

            // 3. KEPUTUSAN AI
            // PERBAIKAN: Gunakan 'title' karena 'description' tidak ada di array weather
            $recommendation = $weatherData['title'];

            if ($workScore < 50) {
                $recommendation = "Trafik sangat padat & cuaca kurang mendukung. Sebaiknya istirahat.";
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
                'work_score' => max(0, $workScore), // Pastikan tidak negatif
                'is_good_to_work' => $workScore >= 60,
                'recommendation' => $recommendation
            ]);

        } catch (\Exception $e) {
            Log::error('Driver Insight Error: ' . $e->getMessage());
            return response()->json([
                'message' => 'Internal Server Error',
                'debug' => $e->getMessage()
            ], 500);
        }
    }
}
