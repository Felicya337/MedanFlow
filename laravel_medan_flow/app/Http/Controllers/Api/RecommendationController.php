<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Route;
use App\Models\TrafficData;
use App\Models\WeatherData;
use Illuminate\Http\Request;

class RecommendationController extends Controller
{
    public function getRecommendations(Request $request)
    {
        // Mengambil semua data rute dari database
        $routes = Route::all();

        $recommendations = $routes->map(function ($route) {
            // Ambil data trafik terbaru (Simulasi AI sederhana)
            $traffic = TrafficData::latest()->first();
            $weather = WeatherData::latest()->first();

            // LOGIKA ESTIMASI WAKTU (ETA)
            // Dasar waktu: Jarak dikali 4 menit per kilometer (rata-rata kecepatan angkot)
            $baseEta = $route->distance * 4;

            // Tambahan waktu jika macet (Traffic Factor)
            $trafficDelay = 0;
            if ($traffic) {
                if ($traffic->congestion_level == 'high') $trafficDelay = 15;
                if ($traffic->congestion_level == 'medium') $trafficDelay = 7;
            }

            // Tambahan waktu jika cuaca buruk (Weather Factor)
            $weatherDelay = 0;
            if ($weather && (str_contains(strtolower($weather->weather_condition), 'rain') ||
                             str_contains(strtolower($weather->weather_condition), 'storm'))) {
                $weatherDelay = 10; // Hujan di Medan biasanya memperlambat arus
            }

            $totalEta = $baseEta + $trafficDelay + $weatherDelay;

            return [
                'id' => $route->id,
                'name' => $route->name,
                'path' => $route->start_point . " -> " . $route->end_point,
                'distance' => $route->distance . " km",
                'eta' => round($totalEta) . " Menit",
                'congestion' => $traffic ? $traffic->congestion_level : 'low',
                'weather_impact' => $weather ? $weather->weather_condition : 'Clear',
                // Menyertakan data koordinat untuk digambar di peta Flutter
                'polyline' => $this->getDummyPolyline($route->id)
            ];
        });

        return response()->json($recommendations);
    }

    /**
     * Helper untuk memberikan titik koordinat jalur rute
     * PHP menggunakan operator '=>' untuk array, bukan ':'
     */
    private function getDummyPolyline($routeId) {
        if($routeId == 1) {
            return [
                ["lat" => 3.5952, "lng" => 98.6722],
                ["lat" => 3.5900, "lng" => 98.6800]
            ];
        }

        return [
            ["lat" => 3.5952, "lng" => 98.6722],
            ["lat" => 3.6000, "lng" => 98.6700]
        ];
    }
}
