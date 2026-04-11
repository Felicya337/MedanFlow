import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class TravelTimePredictionScreen extends StatefulWidget {
  const TravelTimePredictionScreen({super.key});

  @override
  State<TravelTimePredictionScreen> createState() =>
      _TravelTimePredictionScreenState();
}

class _TravelTimePredictionScreenState
    extends State<TravelTimePredictionScreen> {
  final MapController _mapController = MapController();
  final LatLng _medanCenter = const LatLng(3.5952, 98.6722);
  late LatLng _currentMapCenter;

  // State Manajemen Fase
  int _step = 0; // 0 = Pilih Asal, 1 = Pilih Tujuan, 2 = Tampilkan Hasil
  bool _isLoading = false;

  LatLng? _originPoint;
  LatLng? _destPoint;
  Map<String, dynamic>? _predictionData;
  List<LatLng> _routePoints = [];

  final Color primaryColor = const Color(0xFF00796B);

  @override
  void initState() {
    super.initState();
    _currentMapCenter = _medanCenter;
  }

  // Fungsi memanggil API Prediksi Perjalanan di Laravel
  Future<void> _calculateRoute() async {
    if (_originPoint == null || _destPoint == null) return;

    setState(() => _isLoading = true);

    try {
      // Pastikan method getTravelPrediction sudah ada di ApiService Anda
      final response = await ApiService().getTravelPrediction(
        _originPoint!.latitude,
        _originPoint!.longitude,
        _destPoint!.latitude,
        _destPoint!.longitude,
      );

      if (response != null) {
        List<LatLng> points = [];
        if (response['route_geometry'] != null) {
          for (var point in response['route_geometry']) {
            points.add(LatLng(point[1], point[0]));
          }
        } else {
          points = [_originPoint!, _destPoint!];
        }

        setState(() {
          _predictionData = response;
          _routePoints = points;
          _step = 2; // Pindah ke fase Hasil
        });
        
        _mapController.move(
          LatLng(
            (_originPoint!.latitude + _destPoint!.latitude) / 2,
            (_originPoint!.longitude + _destPoint!.longitude) / 2,
          ), 
          13.5
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal menganalisis rute. Cek koneksi ke server."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetScreen() {
    setState(() {
      _step = 0;
      _originPoint = null;
      _destPoint = null;
      _predictionData = null;
      _routePoints.clear();
      _mapController.move(_currentMapCenter, 15.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // 1. LAYER PETA UTAMA (MAPBOX TRAFFIC)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _medanCenter,
              initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && _step < 2) {
                  setState(() => _currentMapCenter = position.center!);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/${ApiService.mapboxTrafficStyle}/tiles/256/{z}/{x}/{y}@2x?access_token=${ApiService.mapboxToken}',
                additionalOptions: const {
                  'accessToken': ApiService.mapboxToken,
                  'id': ApiService.mapboxTrafficStyle,
                },
                userAgentPackageName: 'com.medanflow.app',
              ),
              
              // Garis Rute (Polyline) - Perbaikan Parameter di sini
              if (_step == 2 && _routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: primaryColor,
                      strokeWidth: 5.0,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),
                
              // Marker Lokasi
              MarkerLayer(
                markers: [
                  if (_originPoint != null)
                    Marker(
                      point: _originPoint!,
                      width: 45,
                      height: 45,
                      child: const Icon(Icons.location_on, color: Colors.green, size: 45),
                    ),
                  if (_destPoint != null && _step == 2)
                    Marker(
                      point: _destPoint!,
                      width: 45,
                      height: 45,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 45),
                    ),
                ],
              ),
            ],
          ),

          // 2. PIN SELECTOR MELAYANG
          if (_step < 2)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _step == 0 ? "Titik Keberangkatan" : "Titik Tujuan Perjalanan",
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Icon(
                      Icons.location_on,
                      color: Colors.orange,
                      size: 55,
                    ),
                  ],
                ),
              ),
            ),

          // 3. FLOATING INFO CARD
          if (_step < 2)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15)],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(_step == 0 ? Icons.my_location : Icons.flag_rounded, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _step == 0 ? "Tentukan Lokasi Jemput" : "Tentukan Lokasi Tujuan",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Text("Geser peta untuk memposisikan pin", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. ACTION BUTTON
          if (_step < 2)
            Positioned(
              bottom: 40,
              left: 30,
              right: 30,
              child: SizedBox(
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 8,
                  ),
                  onPressed: () {
                    if (_step == 0) {
                      setState(() {
                        _originPoint = _currentMapCenter;
                        _step = 1;
                      });
                    } else if (_step == 1) {
                      setState(() => _destPoint = _currentMapCenter);
                      _calculateRoute();
                    }
                  },
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text(
                          _step == 0 ? "KONFIRMASI ASAL" : "ANALISIS ESTIMASI WAKTU",
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),

          // 5. KARTU HASIL ANALISIS AI (Step 2)
          if (_step == 2 && _predictionData != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 25, offset: Offset(0, -5))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("ESTIMASI PERJALANAN", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(_predictionData!['predicted_time'], style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_predictionData!['status_color']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            _predictionData!['congestion_level'].toUpperCase(),
                            style: TextStyle(color: _getStatusColor(_predictionData!['status_color']), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniInfo(Icons.route_outlined, "Jarak", _predictionData!['distance']),
                        _buildMiniInfo(Icons.cloud_queue_rounded, "Cuaca", _predictionData!['prediction_factors']['weather']),
                        _buildMiniInfo(Icons.timer_outlined, "Delay", _predictionData!['delay']),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: _resetScreen,
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: const Text("CARI RUTE LAIN", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: primaryColor.withOpacity(0.6), size: 22),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF263238))),
        ],
      ),
    );
  }

  Color _getStatusColor(String colorName) {
    switch (colorName) {
      case 'red': return const Color(0xFFD32F2F);
      case 'orange': return const Color(0xFFF57C00);
      case 'blue': return const Color(0xFF1976D2);
      default: return const Color(0xFF388E3C);
    }
  }
}