<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TrafficData;
use App\Models\WeatherData;
use Illuminate\Http\Request;

class DriverController extends Controller
{
    public function getDashboardInsights()
    {
        $traffic = TrafficData::latest()->first();
        $weather = WeatherData::latest()->first();

        // Logika Sederhana AI Keputusan
        $isGoodToWork = true;
        $reason = "Kondisi Medan saat ini sangat baik untuk menarik.";

        if ($weather && str_contains(strtolower($weather->weather_condition), 'rain')) {
            $reason = "Hujan terdeteksi. Harap waspada jalan licin dan potensi macet di pusat kota.";
        }

        if ($traffic && $traffic->congestion_level == 'high') {
            $isGoodToWork = false;
            $reason = "Trafik Medan sedang sangat padat (Macet Parah). Pertimbangkan untuk menunda perjalanan.";
        }

        return response()->json([
            'weather' => [
                'temp' => $weather ? $weather->temperature . "°C" : "29°C",
                'condition' => $weather ? $weather->weather_condition : "Cerah",
            ],
            'traffic' => [
                'level' => $traffic ? $traffic->congestion_level : "low",
                'description' => $traffic ? "Kepadatan: " . ucfirst($traffic->congestion_level) : "Lancar",
            ],
            'demand' => rand(70, 95) . "%", // Simulasi permintaan penumpang
            'is_good_to_work' => $isGoodToWork,
            'recommendation' => $reason
        ]);
    }
}
