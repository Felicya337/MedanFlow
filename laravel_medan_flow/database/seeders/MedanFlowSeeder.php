<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Role;
use App\Models\User;
use App\Models\Route;
use App\Models\Angkot;
use App\Models\Driver;
use Illuminate\Support\Facades\Hash;

class MedanFlowSeeder extends Seeder
{
    public function run(): void
    {
        // 1. ISI DATA ROLES
        $adminRole = Role::create(['name' => 'admin']);
        $driverRole = Role::create(['name' => 'driver']);
        $guestRole = Role::create(['name' => 'guest']);

        // 2. ISI DATA RUTE (Contoh Rute Populer di Medan)
        $route1 = Route::create([
            'name' => 'KPUM 64',
            'start_point' => 'Terminal Amplas',
            'end_point' => 'Pinang Baris',
            'distance' => 15.5
        ]);

        $route2 = Route::create([
            'name' => 'Morina 81',
            'start_point' => 'Simalingkar',
            'end_point' => 'Amplas',
            'distance' => 12.0
        ]);

        // 3. ISI DATA ANGKOT (Armada)
        $angkot1 = Angkot::create([
            'angkot_number' => '64-001',
            'route_id' => $route1->id,
            'capacity' => 12,
            'status' => 'active'
        ]);

        $angkot2 = Angkot::create([
            'angkot_number' => '81-025',
            'route_id' => $route2->id,
            'capacity' => 12,
            'status' => 'active'
        ]);

        // 4. BUAT AKUN ADMIN (PEMERINTAH / DISHUB)
        User::create([
            'name' => 'Admin Dishub Medan',
            'email' => 'admin@medan.go.id',
            'password' => Hash::make('admin123'),
            'role_id' => $adminRole->id,
        ]);

        // 5. BUAT AKUN DRIVER (SOPIR ANGKOT)
        $userDriver = User::create([
            'name' => 'Bang Ucok Sopir',
            'email' => 'driver@mail.com',
            'password' => Hash::make('driver123'),
            'role_id' => $driverRole->id,
        ]);

        // Hubungkan User ke tabel Driver
        Driver::create([
            'user_id' => $userDriver->id,
            'angkot_id' => $angkot1->id, // Bang Ucok bawa angkot KPUM 64
            'license_number' => 'SIM-123456789',
            'vehicle_plate' => 'BK 1234 AA',
            'status' => 'active',
        ]);

        $this->command->info('Data Medan Flow berhasil di-seed!');
    }
}
