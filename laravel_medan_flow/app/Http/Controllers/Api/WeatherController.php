<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;

class WeatherController extends Controller
{
    // Fungsi ini dipanggil via URL API /api/weather/current
    public function getCurrentWeather()
    {
        return response()->json($this->getWeatherData());
    }

    // Fungsi internal agar datanya bisa diambil oleh DriverController tanpa error
    public function getWeatherData()
    {
        return Cache::remember('weather_medan', 900, function () {
            $apiKey = env('OPENWEATHER_API_KEY');
            $city = "Medan";

            try {
                $response = Http::get("https://api.openweathermap.org/data/2.5/weather", [
                    'q' => $city,
                    'appid' => $apiKey,
                    'units' => 'metric',
                    'lang' => 'id'
                ]);

                if ($response->successful()) {
                    $data = $response->json();
                    $condition = $data['weather'][0]['main'] ?? 'Clear';

                    $icon = 'sunny';
                    if (in_array($condition, ['Rain', 'Drizzle', 'Thunderstorm'])) $icon = 'rainy';
                    if ($condition == 'Clouds') $icon = 'cloudy';

                    return [
                        'temp' => round($data['main']['temp']) . "°C",
                        'condition' => ucfirst($data['weather'][0]['description']),
                        'icon' => $icon,
                        'humidity' => $data['main']['humidity'] . "%",
                        'wind_speed' => $data['wind']['speed'] . " m/s",
                        'location' => 'Medan, Indonesia',
                        'description' => $this->generateAdvice($condition)
                    ];
                }
            } catch (\Exception $e) {
                \Log::error("Weather API Error: " . $e->getMessage());
            }

            // Fallback jika API gagal
            return [
                'temp' => '29°C',
                'condition' => 'Berawan',
                'icon' => 'cloudy',
                'humidity' => '70%',
                'wind_speed' => '10 km/h',
                'location' => 'Medan',
                'description' => 'Gagal mengambil data cuaca terbaru.'
            ];
        });
    }

    private function generateAdvice($condition)
    {
        if (in_array($condition, ['Rain', 'Thunderstorm'])) {
            return "Medan sedang hujan. Harap waspada jalan licin dan potensi banjir.";
        }
        return "Cuaca Medan cukup cerah untuk menarik angkot hari ini.";
    }
}
