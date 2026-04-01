<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\{User, Driver, Role};
use App\Mail\OtpMail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\{Hash, Mail, DB, Validator};
use Carbon\Carbon;

class AuthController extends Controller
{
    public function registerDriver(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:8',
            'vehicle_plate' => 'required',
            'angkot_id' => 'required|exists:angkots,id'
        ]);

        if ($validator->fails()) return response()->json($validator->errors(), 422);

        return DB::transaction(function () use ($request) {
            // 1. Buat User
            $user = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'role_id' => 2, // Driver
            ]);

            // 2. Buat Driver Pending
            Driver::create([
                'user_id' => $user->id,
                'angkot_id' => $request->angkot_id,
                'vehicle_plate' => $request->vehicle_plate,
                'status' => 'pending', // Wajib persetujuan Admin
            ]);

            // 3. Generate & Kirim OTP
            $otpCode = rand(100000, 999999);
            DB::table('otps')->insert([
                'email' => $request->email,
                'code' => $otpCode,
                'expires_at' => Carbon::now()->addMinutes(10)
            ]);

            Mail::to($request->email)->send(new OtpMail($otpCode));

            return response()->json(['message' => 'Registrasi berhasil. Silakan cek email untuk kode OTP.']);
        });
    }

    public function verifyOtp(Request $request)
    {
        $request->validate(['email' => 'required|email', 'code' => 'required']);

        $otp = DB::table('otps')
            ->where('email', $request->email)
            ->where('code', $request->code)
            ->where('expires_at', '>', Carbon::now())
            ->first();

        if (!$otp) return response()->json(['message' => 'OTP tidak valid atau kadaluarsa.'], 400);

        User::where('email', $request->email)->update(['email_verified_at' => now()]);
        DB::table('otps')->where('email', $request->email)->delete();

        return response()->json(['message' => 'Email berhasil diverifikasi. Menunggu persetujuan Admin.']);
    }

    // UPDATE LOGIN: Cegah Driver login jika masih pending
    public function login(Request $request)
    {
        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Email atau Password salah.'], 401);
        }

        if ($user->role_id == 2) {
            $driver = $user->driver;
            if ($user->email_verified_at == null) return response()->json(['message' => 'Verifikasi email dulu.'], 403);
            if ($driver->status == 'pending') return response()->json(['message' => 'Akun Anda sedang ditinjau oleh Admin.'], 403);
        }

        return response()->json([
            'token' => $user->createToken('auth_token')->plainTextToken,
            'user' => $user->load('role')
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logged out']);
    }
}
