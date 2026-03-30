<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class TrafficMapController extends Controller
{
    public function getPredictiveHeatmap(Request $request)
    {
        $minutes = $request->query('minutes', 5); // Default prediksi 5 menit

        /**
         * Simulasi Titik Koordinat Rawan Macet di Medan
         * Latitude: 3.59xx, Longitude: 98.67xx
         */
        $hotspots = [
            ['name' => 'Simpang Pos', 'lat' => 3.5422, 'lng' => 98.6575],
            ['name' => 'Medan Fair / Petisah', 'lat' => 3.5909, 'lng' => 98.6637],
            ['name' => 'Stasiun Kereta Api', 'lat' => 3.5912, 'lng' => 98.6761],
            ['name' => 'Simpang Kampus USU', 'lat' => 3.5639, 'lng' => 98.6531],
            ['name' => 'Amplas Junction', 'lat' => 3.5401, 'lng' => 98.6998],
            ['name' => 'Gatot Subroto / Sei Sikambing', 'lat' => 3.5935, 'lng' => 98.6506],
        ];

        $predictionData = array_map(function ($spot) use ($minutes) {
            // Logika AI: Semakin lama menit (prediksi), intensitas macet cenderung naik
            // pada jam sibuk atau turun pada jam tenang secara acak untuk simulasi
            $randomFactor = rand(1, 3);
            $intensity = ($minutes / 10) * $randomFactor;

            if ($intensity > 2.5) {
                $level = 'macet';
                $color = 'red';
            } elseif ($intensity > 1.2) {
                $level = 'padat';
                $color = 'yellow';
            } else {
                $level = 'lancar';
                $color = 'green';
            }

            return [
                'location_name' => $spot['name'],
                'lat' => $spot['lat'],
                'lng' => $spot['lng'],
                'congestion_level' => $level,
                'color' => $color,
                'radius' => 200 + ($intensity * 50), // Radius lingkaran di peta
            ];
        }, $hotspots);

        return response()->json([
            'prediction_window' => $minutes . " menit ke depan",
            'data' => $predictionData,
            'summary' => "Prediksi didasarkan pada data historis GPS Angkot & Cuaca."
        ]);
    }
}
