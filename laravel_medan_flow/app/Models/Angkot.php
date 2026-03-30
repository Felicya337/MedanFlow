<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Angkot extends Model
{
    use HasFactory;

    protected $fillable = ['angkot_number', 'route_id', 'capacity', 'status'];

    public function route()
    {
        return $this->belongsTo(Route::class);
    }

    public function drivers()
    {
        return $this->hasMany(Driver::class);
    }

    public function trips()
    {
        return $this->hasMany(Trip::class);
    }
}
