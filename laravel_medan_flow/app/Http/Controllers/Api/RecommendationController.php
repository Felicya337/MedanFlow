<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Route;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class RecommendationController extends Controller
{
    public function getRecommendations(Request $request)
    {
        $userLat = $request->query('lat');
        $userLng = $request->query('lng');

        // PASTI LAKUKAN INI:
        // 1. Login ke mapbox.com
        // 2. Cari "Default public token" yang berawalan pk.xxx
        // 3. Masukkan ke variabel di bawah ini (Ganti teks di bawah dengan token Anda)
        $token = env('MAPBOX_ACCESS_TOKEN');

        // Tujuan: Pinang Baris
        $destLat = 3.6031;
        $destLng = 98.6250;

        $routes = Route::all();
        $weatherData = app(WeatherController::class)->getWeatherData();

        $recommendations = $routes->map(function ($route) use ($userLat, $userLng, $token, $destLat, $destLng) {
            $geometry = [];
            $duration = 25;
            $distance = $route->distance;

            if ($userLat && $userLng) {
                // PROFILE: driving-traffic (Inilah yang mendeteksi kemacetan real-time)
                $url = "https://api.mapbox.com/directions/v5/mapbox/driving-traffic/{$userLng},{$userLat};{$destLng},{$destLat}";

                $response = Http::withoutVerifying()->get($url, [
                    'geometries'   => 'geojson',
                    'overview'     => 'full',
                    'access_token' => $token,
                ]);

                if ($response->successful()) {
                    $data = $response->json();
                    if (!empty($data['routes'])) {
                        $geometry = $data['routes'][0]['geometry']['coordinates'];
                        $duration = $data['routes'][0]['duration'] / 60; // Akurat dengan trafik
                        $distance = $data['routes'][0]['distance'] / 1000;
                    }
                } else {
                    // Log error untuk debug
                    \Log::error("Mapbox Error: " . $response->body());
                }
            }

            return [
                'id' => $route->id,
                'name' => $route->name,
                'distance' => round($distance, 1) . " km",
                'eta' => round($duration) . " Menit",
                'congestion' => ($duration > 35) ? 'high' : 'low',
                'geometry' => $geometry,
            ];
        });

        return response()->json($recommendations);
    }
}
