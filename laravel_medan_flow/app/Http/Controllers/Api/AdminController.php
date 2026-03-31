<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Angkot;
use App\Models\Trip;
use App\Models\TrafficData;
use App\Models\User;
use Illuminate\Http\Request;
use Carbon\Carbon;

class AdminController extends Controller
{
    public function getDashboardStats()
    {
        // 1. Hitung Ringkasan Data
        $totalAngkots = Angkot::count();
        $activeTrips = Trip::where('status', 'ongoing')->count();
        $totalDrivers = User::where('role_id', 2)->count();
        $congestionIndex = rand(15, 85); // Simulasi Index Kemacetan Kota (%)

        // 2. Simulasi Data Grafik (7 Hari Terakhir)
        $chartData = [
            ['day' => 'Sen', 'value' => 45],
            ['day' => 'Sel', 'value' => 52],
            ['day' => 'Rab', 'value' => 38],
            ['day' => 'Kam', 'value' => 65],
            ['day' => 'Jum', 'value' => 82],
            ['day' => 'Sab', 'value' => 40],
            ['day' => 'Min', 'value' => 30],
        ];

        // 3. Titik Kemacetan Terkini (Untuk Monitoring)
        $hotspots = TrafficData::with('weather')->latest()->take(5)->get();

        return response()->json([
            'overview' => [
                'total_angkots' => $totalAngkots,
                'active_now' => $activeTrips,
                'total_drivers' => $totalDrivers,
                'congestion_index' => $congestionIndex . "%",
            ],
            'chart_data' => $chartData,
            'recent_incidents' => [
                ['id' => 1, 'loc' => 'Jl. Thamrin', 'status' => 'Macet Parah', 'time' => '10 mnt lalu'],
                ['id' => 2, 'loc' => 'Simpang Pos', 'status' => 'Padat Merayap', 'time' => '15 mnt lalu'],
            ]
        ]);
    }
}
