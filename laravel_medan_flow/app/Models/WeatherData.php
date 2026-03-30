<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WeatherData extends Model
{
    use HasFactory;

    // Tabel ini tidak menggunakan timestamps (created_at/updated_at) default Laravel di migrasi Anda
    public $timestamps = false;

    protected $fillable = [
        'latitude',
        'longitude',
        'temperature',
        'weather_condition',
        'humidity',
        'wind_speed',
        'recorded_at'
    ];

    protected $casts = [
        'recorded_at' => 'datetime',
    ];

    public function trafficData()
    {
        return $this->hasMany(TrafficData::class, 'weather_id');
    }
}
