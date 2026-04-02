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

  Future<void> _calculateRoute() async {
    if (_originPoint == null || _destPoint == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService().getTravelPrediction(
        _originPoint!.latitude,
        _originPoint!.longitude,
        _destPoint!.latitude,
        _destPoint!.longitude,
      );

      if (result != null) {
        // Ambil data polyline dari JSON
        List<LatLng> points = [];
        if (result['route_geometry'] != null) {
          for (var point in result['route_geometry']) {
            points.add(LatLng(point[1], point[0])); // Balik LngLat jadi LatLng
          }
        }

        setState(() {
          _predictionData = result;
          _routePoints = points;
          _step = 2; // Pindah ke fase Hasil
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal mengambil estimasi waktu. Cek koneksi Anda."),
          backgroundColor: Colors.redAccent,
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
      extendBodyBehindAppBar: true, // Peta tembus ke belakang AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // 1. LAYER PETA UTAMA
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_medan_flow',
              ),
              // Garis Rute (Hanya muncul di Step 2)
              if (_step == 2 && _routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blueAccent,
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
              // Marker yang sudah ditancapkan
              MarkerLayer(
                markers: [
                  if (_originPoint != null)
                    Marker(
                      point: _originPoint!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  if (_destPoint != null && _step == 2)
                    Marker(
                      point: _destPoint!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // 2. PIN MELAYANG DI TENGAH (Hanya untuk Step 0 dan 1)
          if (_step < 2)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _step == 0
                            ? "Geser peta untuk Titik Asal"
                            : "Geser peta untuk Titik Tujuan",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Icon(
                      Icons.location_on,
                      color: _step == 0
                          ? Colors.green
                          : Colors.red, // Hijau untuk asal, Merah untuk tujuan
                      size: 50,
                    ),
                  ],
                ),
              ),
            ),

          // 3. KARTU INFORMASI DI ATAS
          if (_step < 2)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _step == 0 ? Icons.my_location : Icons.flag,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _step == 0
                                ? "Tentukan Lokasi Jemput"
                                : "Tentukan Lokasi Tujuan",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "Arahkan pin tepat di jalan raya",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. TOMBOL AKSI DI BAWAH (Step 0 dan 1)
          if (_step < 2)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    if (_step == 0) {
                      setState(() {
                        _originPoint = _currentMapCenter;
                        _step = 1; // Lanjut pilih tujuan
                      });
                    } else if (_step == 1) {
                      setState(() => _destPoint = _currentMapCenter);
                      _calculateRoute(); // Langsung hitung API
                    }
                  },
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _step == 0
                              ? "SET LOKASI JEMPUT"
                              : "CEK ESTIMASI WAKTU",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),

          // 5. KARTU HASIL PREDIKSI (Hanya Step 2)
          if (_step == 2 && _predictionData != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar (Garis kecil di atas bottom sheet)
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "ESTIMASI TIBA",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _predictionData!['predicted_time'],
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              _predictionData!['status_color'],
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _predictionData!['congestion_level'],
                            style: TextStyle(
                              color: _getStatusColor(
                                _predictionData!['status_color'],
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniInfo(
                          Icons.map,
                          "Jarak",
                          _predictionData!['distance'],
                        ),
                        _buildMiniInfo(
                          Icons.wb_cloudy,
                          "Cuaca",
                          _predictionData!['prediction_factors']['weather'],
                        ),
                        _buildMiniInfo(
                          Icons.traffic,
                          "Delay",
                          _predictionData!['delay'],
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _resetScreen,
                        child: const Text(
                          "CARI RUTE LAIN",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
    return Column(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }

  Color _getStatusColor(String colorName) {
    switch (colorName) {
      case 'red':
        return const Color(0xFFE53935);
      case 'orange':
        return const Color(0xFFFB8C00);
      case 'blue':
        return const Color(0xFF1E88E5);
      default:
        return const Color(0xFF43A047);
    }
  }
}
