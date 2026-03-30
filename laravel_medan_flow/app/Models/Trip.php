<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Trip extends Model
{
    use HasFactory;

    protected $fillable = [
        'driver_id',
        'angkot_id',
        'start_time',
        'end_time',
        'status',
        'current_status',
        'current_eta'
    ];

    protected $casts = [
        'start_time' => 'datetime',
        'end_time' => 'datetime',
    ];

    public function driver()
    {
        return $this->belongsTo(Driver::class);
    }

    public function angkot()
    {
        return $this->belongsTo(Angkot::class);
    }

    public function locations()
    {
        return $this->hasMany(TripLocation::class);
    }
}
