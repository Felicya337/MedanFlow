<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class WeatherController extends Controller
{
    private $lat = 3.5952;
    private $lon = 98.6722;

    public function getCurrentWeather()
    {
        return response()->json($this->getWeatherData());
    }

    public function getWeatherData()
    {
        return Cache::remember('weather_medan', 900, function () {
            $key = env('OPENWEATHER_API_KEY');

            try {
                $res = Http::withoutVerifying()->get('https://api.openweathermap.org/data/2.5/weather', [
                    'lat'   => $this->lat,
                    'lon'   => $this->lon,
                    'appid' => $key,
                    'units' => 'metric',
                    'lang'  => 'id',
                ]);

                if ($res->successful()) {
                    $data = $res->json();
                    $condition   = $data['weather'][0]['main'] ?? 'Clear';
                    $description = $data['weather'][0]['description'] ?? 'Cerah';
                    $temp        = round($data['main']['temp'] ?? 29);
                    $humidity    = $data['main']['humidity'] ?? 70;
                    $windSpeed   = round($data['wind']['speed'] ?? 5, 2);
                    $location    = ($data['name'] ?? 'Medan') . ', Indonesia';

                    $condLower = strtolower($condition);
                    $icon = 'sunny';
                    if (strpos($condLower, 'rain') !== false || strpos($condLower, 'drizzle') !== false || strpos($condLower, 'thunderstorm') !== false) {
                        $icon = 'rainy';
                    } elseif (strpos($condLower, 'cloud') !== false) {
                        $icon = 'cloudy';
                    }

                    $message = $this->generateMessage($condition, $temp, $humidity);

                    return [
                        'condition'   => ucfirst($description),
                        'icon'        => $icon,
                        'temp'        => $temp . '°C',
                        'humidity'    => $humidity . '%',
                        'wind_speed'  => $windSpeed . ' m/s',
                        'location'    => $location,
                        'title'       => $message['title'],
                        'tips'        => $message['tips'],
                    ];
                }
            } catch (\Exception $e) {
                Log::error('Weather API Error: ' . $e->getMessage());
            }

            // FALLBACK PASTI (Sesuai Struktur)
            return [
                'condition' => 'Berawan',
                'icon' => 'cloudy',
                'temp' => '29°C',
                'humidity' => '70%',
                'wind_speed' => '10 m/s',
                'location' => 'Medan, Indonesia',
                'title' => 'Mendung – tetap waspada',
                'tips' => ['Siapkan perlengkapan hujan', 'Perhatikan kondisi jalan'],
            ];
        });
    }

    private function generateMessage($condition, $temp, $humidity)
    {
        $cond = strtolower($condition);
        if (strpos($cond, 'thunderstorm') !== false) {
            return ['title' => 'Badai – hindari luar ruangan', 'tips' => ['Waspada petir', 'Keselamatan utama']];
        }
        if (strpos($cond, 'rain') !== false || strpos($cond, 'drizzle') !== false) {
            return ['title' => 'Hujan – jalan licin', 'tips' => ['Gunakan jas hujan', 'Hati-hati berkendara']];
        }
        if ($temp >= 30) {
            return ['title' => 'Cuaca panas terik', 'tips' => ['Minum air cukup', 'Gunakan pelindung']];
        }
        return ['title' => 'Cuaca mendukung', 'tips' => ['Selamat beraktivitas', 'Jaga kesehatan']];
    }
}
