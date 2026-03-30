<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Driver extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'angkot_id',
        'license_number',
        'vehicle_plate',
        'status'
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function angkot()
    {
        return $this->belongsTo(Angkot::class);
    }

    public function trips()
    {
        return $this->hasMany(Trip::class);
    }
}
