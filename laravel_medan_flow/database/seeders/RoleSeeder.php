<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use App\Models\Role;
use App\Models\User;

class RoleSeeder extends Seeder {
    public function run() {
        Role::create(['name' => 'admin']);
        Role::create(['name' => 'driver']);
        Role::create(['name' => 'guest']);

        // Buat Akun Test
        User::create([
            'name' => 'Sopir Medan',
            'email' => 'driver@mail.com',
            'password' => bcrypt('password'),
            'role_id' => 2
        ]);
    }
}
