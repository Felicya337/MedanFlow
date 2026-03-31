<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Driver;
use App\Models\Angkot;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class DriverManagementController extends Controller
{
    public function index()
    {
        // Mengambil driver beserta data user dan data angkotnya
        return response()->json(Driver::with(['user', 'angkot'])->get());
    }

    public function getAngkots()
    {
        return response()->json(Angkot::all());
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:6',
            'angkot_id' => 'required',
            'vehicle_plate' => 'required'
        ]);

        try {
            return DB::transaction(function () use ($request) {
                $user = User::create([
                    'name' => $request->name,
                    'email' => $request->email,
                    'password' => Hash::make($request->password),
                    'role_id' => 2 // Role Driver
                ]);

                $driver = Driver::create([
                    'user_id' => $user->id,
                    'angkot_id' => $request->angkot_id,
                    'vehicle_plate' => $request->vehicle_plate,
                    'license_number' => $request->license_number ?? '-',
                    'status' => 'active'
                ]);

                return response()->json(['message' => 'Driver Berhasil Ditambah', 'data' => $driver]);
            });
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 500);
        }
    }

    public function update(Request $request, $id)
    {
        $driver = Driver::findOrFail($id);
        $user = User::findOrFail($driver->user_id);

        try {
            DB::transaction(function () use ($request, $driver, $user) {
                $user->update([
                    'name' => $request->name,
                    'email' => $request->email
                ]);

                $driver->update([
                    'angkot_id' => $request->angkot_id,
                    'vehicle_plate' => $request->vehicle_plate
                ]);
            });
            return response()->json(['message' => 'Update Berhasil']);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 500);
        }
    }

    public function destroy($id)
    {
        $driver = Driver::findOrFail($id);
        User::where('id', $driver->user_id)->delete(); // Akan hapus Driver juga karena cascade
        return response()->json(['message' => 'Driver Dihapus']);
    }
}
