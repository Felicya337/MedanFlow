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
                $res = Http::get('https://api.openweathermap.org/data/2.5/weather', [
                    'lat'   => $this->lat,
                    'lon'   => $this->lon,
                    'appid' => $key,
                    'units' => 'metric',
                    'lang'  => 'id',
                ]);

                if ($res->successful()) {
                    $data = $res->json();

                    $condition   = $data['weather'][0]['main'];
                    $description = $data['weather'][0]['description'];
                    $temp        = round($data['main']['temp']);
                    $humidity    = $data['main']['humidity'];
                    $windSpeed   = round($data['wind']['speed'], 2);
                    $location    = $data['name'] . ', Indonesia';

                    // ICON
                    $condLower = strtolower($condition);
                    $icon = 'sunny';

                    if (
                        strpos($condLower, 'rain') !== false ||
                        strpos($condLower, 'drizzle') !== false ||
                        strpos($condLower, 'thunderstorm') !== false
                    ) {
                        $icon = 'rainy';
                    } elseif (strpos($condLower, 'cloud') !== false) {
                        $icon = 'cloudy';
                    }

                    // 🔥 Ambil message (title + tips)
                    $message = $this->generateMessage($condition, $temp, $humidity);

                    return [
                        'condition'   => ucfirst($description),
                        'icon'        => $icon,
                        'temp'        => $temp . '°C',
                        'humidity'    => $humidity . '%',
                        'wind_speed'  => $windSpeed . ' m/s',
                        'location'    => $location,

                        // ⬇️ INI YANG DIPAKAI UI
                        'title'       => $message['title'],
                        'tips'        => $message['tips'],
                    ];
                }
            } catch (\Exception $e) {
                Log::error('Weather API Error', [
                    'message' => $e->getMessage()
                ]);
            }

            // Fallback
            return [
                'condition' => 'Berawan',
                'icon' => 'cloudy',
                'temp' => '29°C',
                'humidity' => '70%',
                'wind_speed' => '10 m/s',
                'location' => 'Medan, Indonesia',
                'title' => 'Mendung – bisa hujan sewaktu-waktu',
                'tips' => [
                    'Simpan payung kecil',
                    'Udara terasa lembap',
                    'Perhatikan kondisi sekitar'
                ],
            ];
        });
    }

    // 🔥 FORMAT SESUAI UI CARD
    private function generateMessage($condition, $temp, $humidity)
    {
        $cond = strtolower($condition);

        if (strpos($cond, 'thunderstorm') !== false) {
            return [
                'title' => 'Badai – hindari aktivitas luar',
                'tips' => [
                    'Tetap di dalam ruangan',
                    'Waspada petir',
                    'Utamakan keselamatan'
                ]
            ];
        }

        if (strpos($cond, 'rain') !== false || strpos($cond, 'drizzle') !== false) {
            return [
                'title' => 'Hujan – jalan bisa licin',
                'tips' => [
                    'Bawa payung atau jas hujan',
                    'Hati-hati saat berkendara',
                    'Siapkan waktu perjalanan'
                ]
            ];
        }

        if (strpos($cond, 'cloud') !== false) {
            return [
                'title' => 'Mendung – bisa hujan sewaktu-waktu',
                'tips' => [
                    'Simpan payung kecil',
                    'Udara terasa lembap',
                    'Perhatikan kondisi sekitar'
                ]
            ];
        }

        if ($temp >= 33) {
            return [
                'title' => 'Panas tinggi',
                'tips' => [
                    'Perbanyak minum',
                    'Hindari matahari langsung',
                    'Gunakan pelindung'
                ]
            ];
        }

        if ($temp >= 30) {
            return [
                'title' => 'Cuaca panas',
                'tips' => [
                    'Gunakan sunscreen',
                    'Istirahat cukup',
                    'Tetap terhidrasi'
                ]
            ];
        }

        if ($temp >= 26) {
            return [
                'title' => 'Cuaca hangat dan nyaman',
                'tips' => [
                    'Cocok untuk aktivitas luar',
                    'Tetap jaga kondisi tubuh'
                ]
            ];
        }

        return [
            'title' => 'Cuaca sejuk dan nyaman',
            'tips' => [
                'Nikmati aktivitas harian',
                'Jaga kesehatan'
            ]
        ];
    }
}
