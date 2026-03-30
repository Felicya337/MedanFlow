<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TrafficData;
use App\Models\WeatherData;
use Illuminate\Http\Request;
use Carbon\Carbon;

class NotificationController extends Controller
{
    public function getSmartNotifications()
    {
        // Simulasi pengambilan data kondisi kota Medan saat ini
        $traffic = TrafficData::latest()->first();
        $weather = WeatherData::latest()->first();
        $now = Carbon::now('Asia/Jakarta');

        $notifications = [];

        // 1. Logika Notifikasi Cuaca (Berdasarkan weather_data)
        if ($weather && str_contains(strtolower($weather->weather_condition), 'rain')) {
            $notifications[] = [
                'id' => 1,
                'type' => 'weather',
                'title' => 'Peringatan Cuaca: Hujan Deras',
                'message' => 'Wilayah Medan terpantau hujan. Harap waspada genangan air dan siapkan payung jika ingin menunggu Angkot.',
                'time' => $now->diffForHumans(),
                'is_critical' => true
            ];
        }

        // 2. Logika Notifikasi Kemacetan (Berdasarkan traffic_data)
        if ($traffic && $traffic->congestion_level == 'high') {
            $notifications[] = [
                'id' => 2,
                'type' => 'traffic',
                'title' => 'Kemacetan Terdeteksi',
                'message' => 'Terjadi kepadatan tinggi di sekitar Jl. Gatot Subroto. Gunakan rute alternatif atau berangkat lebih awal.',
                'time' => $now->subMinutes(5)->diffForHumans(),
                'is_critical' => true
            ];
        }

        // 3. Logika Notifikasi Edukasi/Saran (Rekomendasi Rute)
        $notifications[] = [
            'id' => 3,
            'type' => 'suggestion',
            'title' => 'Tips Rute Pintar',
            'message' => 'Gunakan fitur "Rute Pintar" untuk mendapatkan jalur tercepat menuju Terminal Amplas saat jam pulang kerja.',
            'time' => '1 jam yang lalu',
            'is_critical' => false
        ];

        return response()->json([
            'unread_count' => count(array_filter($notifications, fn($n) => $n['is_critical'])),
            'alerts' => $notifications
        ]);
    }
}
