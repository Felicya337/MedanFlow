<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\TripController;
use App\Http\Controllers\Api\RecommendationController;
use App\Http\Controllers\Api\TrafficMapController;
use App\Http\Controllers\Api\PredictionController;

// Public Routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::get('/recommendations', [RecommendationController::class, 'getRecommendations']);
Route::get('/predict-time', [PredictionController::class, 'getTravelTimePrediction']);
Route::get('/traffic-heatmap', [TrafficMapController::class, 'getPredictiveHeatmap']);

// Protected Routes
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    // Trip Routes
    Route::post('/trips/start', [TripController::class, 'startTrip']);
    Route::post('/trips/{id}/location', [TripController::class, 'updateLocation']);
    Route::get('/trips/active', [TripController::class, 'getActiveAngkots']);
});
