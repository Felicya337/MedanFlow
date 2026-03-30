<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Route extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'start_point', 'end_point', 'distance'];

    public function angkots()
    {
        return $this->hasMany(Angkot::class);
    }

    public function predictions()
    {
        return $this->hasMany(Prediction::class);
    }
}
