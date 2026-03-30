<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TrafficData extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $fillable = [
        'latitude',
        'longitude',
        'congestion_level',
        'weather_id',
        'recorded_at'
    ];

    protected $casts = [
        'recorded_at' => 'datetime',
    ];

    public function weather()
    {
        return $this->belongsTo(WeatherData::class, 'weather_id');
    }
}
