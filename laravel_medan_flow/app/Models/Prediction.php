<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Prediction extends Model
{
    use HasFactory;

    protected $fillable = [
        'route_id',
        'predicted_congestion',
        'predicted_eta',
        'weather_factor'
    ];

    public function route()
    {
        return $this->belongsTo(Route::class);
    }
}
