<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/test-query', function () {
    DB::enableQueryLog();

    $data = DB::table('users')->get();

    dd(DB::getQueryLog());
});
