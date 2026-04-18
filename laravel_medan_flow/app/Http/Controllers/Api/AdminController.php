<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Angkot;
use App\Models\Trip;
use App\Models\TrafficData;
use App\Models\User;
use App\Models\Driver;
use Illuminate\Http\Request;
use Carbon\Carbon;

class AdminController extends Controller
{
    public function getDashboardStats()
    {
        try {
            // Mengambil data real dari database
            $activeTrips = Trip::where('status', 'ongoing')->count() ?? 0;
            $totalDrivers = User::where('role_id', 2)->count() ?? 0;
            $totalAngkots = Angkot::count() ?? 0;

            // Data Mingguan untuk Grafik (Pastikan key: chart_data)
            $chart_data = [
                ['day' => 'Sen', 'value' => 45],
                ['day' => 'Sel', 'value' => 52],
                ['day' => 'Rab', 'value' => 38],
                ['day' => 'Kam', 'value' => 65],
                ['day' => 'Jum', 'value' => 82],
                ['day' => 'Sab', 'value' => 40],
                ['day' => 'Min', 'value' => 30],
            ];

            return response()->json([
                'status' => 'success',
                'overview' => [
                    'active_now' => $activeTrips,
                    'total_drivers' => $totalDrivers,
                    'total_angkots' => $totalAngkots,
                    'congestion_index' => "42%",
                ],
                'chart_data' => $chart_data,
                'recent_incidents' => [
                    ['loc' => 'Jl. Thamrin', 'status' => 'Macet Parah', 'time' => '10 mnt lalu'],
                    ['loc' => 'Simpang Pos', 'status' => 'Padat Merayap', 'time' => '15 mnt lalu'],
                ]
            ]);
        } catch (\Exception $e) {
            // Mencatat error asli ke storage/logs/laravel.log agar Anda bisa cek
            Log::error("Admin Stats Error: " . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Internal Server Error: ' . $e->getMessage()
            ], 500);
        }
    }

    public function getPendingDrivers()
    {
        // Mengambil driver yang statusnya 'pending' beserta data User dan Angkot-nya
        $pending = Driver::with(['user', 'angkot.route'])
            ->where('status', 'pending')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($pending);
    }

    public function approveDriver(Request $request, $id)
    {
        $driver = Driver::findOrFail($id);

        // Update status menjadi active
        $driver->update(['status' => 'active']);

        return response()->json([
            'message' => 'Driver ' . $driver->user->name . ' telah disetujui dan sekarang dapat menarik angkot.'
        ]);
    }

    public function rejectDriver(Request $request, $id)
    {
        $driver = Driver::findOrFail($id);
        $userName = $driver->user->name;

        // Menghapus data user otomatis menghapus driver karena cascade delete
        $driver->user->delete();

        return response()->json([
            'message' => 'Pendaftaran Driver ' . $userName . ' telah ditolak dan dihapus.'
        ]);
    }
}
