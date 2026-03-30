import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class TrackingProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  Timer? _timer;
  bool _isTracking = false;
  int? _currentTripId;

  bool get isTracking => _isTracking;

  Future<void> toggleTracking() async {
    if (_isTracking) {
      _stopTracking();
    } else {
      await _startTracking();
    }
  }

  Future<void> _startTracking() async {
    try {
      // 1. Cek Izin Lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) return;
      }

      // 2. Panggil API Start Trip
      _currentTripId = await _apiService.startTrip();
      
      _isTracking = true;
      notifyListeners();

      // 3. Jalankan Timer Update Lokasi setiap 10 detik
      _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        Position pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        
        await _apiService.updateLocation(
          _currentTripId!, 
          pos.latitude, 
          pos.longitude, 
          pos.speed
        );
        print("Lokasi terkirim: ${pos.latitude}, ${pos.longitude}");
      });
    } catch (e) {
      print("Error Start Tracking: $e");
    }
  }

  void _stopTracking() {
    _timer?.cancel();
    _isTracking = false;
    _currentTripId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}