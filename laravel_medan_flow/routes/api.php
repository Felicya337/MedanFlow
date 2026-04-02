<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\TripController;
use App\Http\Controllers\Api\RecommendationController;
use App\Http\Controllers\Api\TrafficMapController;
use App\Http\Controllers\Api\PredictionController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\DriverManagementController;
use App\Http\Controllers\Api\WeatherController;
use App\Http\Controllers\Api\DriverController;
use Illuminate\Support\Facades\Route;

// Public Routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::get('/recommendations', [RecommendationController::class, 'getRecommendations']);
Route::get('/predict-time', [PredictionController::class, 'getTravelTimePrediction']);
Route::post('/predictions/travel-time', [PredictionController::class, 'getTravelTimePrediction']);
Route::get('/traffic-heatmap', [TrafficMapController::class, 'getPredictiveHeatmap']);
Route::get('/weather/current', [WeatherController::class, 'getCurrentWeather']);

Route::get('/driver/insights', [DriverController::class, 'getDashboardInsights']);
Route::post('/register-driver', [AuthController::class, 'registerDriver']);
Route::post('/verify-otp', [AuthController::class, 'verifyOtp']);

// Protected Routes
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    // Trip Routes
    Route::post('/trips/start', [TripController::class, 'startTrip']);
    Route::post('/trips/{id}/location', [TripController::class, 'updateLocation']);
    Route::get('/trips/active', [TripController::class, 'getActiveAngkots']);

    Route::get('/admin/stats', [AdminController::class, 'getDashboardStats']);
    Route::get('/admin/drivers', [DriverManagementController::class, 'index']);
    Route::get('/admin/angkots', [DriverManagementController::class, 'getAngkots']);
    Route::post('/admin/drivers', [DriverManagementController::class, 'store']);
    Route::put('/admin/drivers/{id}', [DriverManagementController::class, 'update']);
    Route::delete('/admin/drivers/{id}', [DriverManagementController::class, 'destroy']);
    Route::get('/admin/pending-drivers', [AdminController::class, 'getPendingDrivers']);
    Route::post('/admin/approve-driver/{id}', [AdminController::class, 'approveDriver']);
    Route::post('/admin/reject-driver/{id}', [AdminController::class, 'rejectDriver']);
});
