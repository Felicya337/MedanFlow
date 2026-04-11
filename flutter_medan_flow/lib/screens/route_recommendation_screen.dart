import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class RouteRecommendationScreen extends StatefulWidget {
  const RouteRecommendationScreen({super.key});

  @override
  State<RouteRecommendationScreen> createState() => _RouteRecommendationScreenState();
}

class _RouteRecommendationScreenState extends State<RouteRecommendationScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();
  List _recommendations = [];
  bool _isLoading = false;
  
  final TextEditingController _originController = TextEditingController(text: "Mendeteksi lokasi...");
  final TextEditingController _destController = TextEditingController(text: "Pinang Baris");
  
  Position? _userPosition;
  List<LatLng> _currentPolyline = []; // Tempat menyimpan garis rute

  final Color primaryColor = const Color(0xFF00796B);

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    Position position = await Geolocator.getCurrentPosition();
    
    // Cheat Emulator (Medan)
    position = Position(
      latitude: 3.5952, longitude: 98.6722,
      timestamp: DateTime.now(), accuracy: 1, altitude: 1, heading: 1, speed: 1, speedAccuracy: 1,
      altitudeAccuracy: 1, headingAccuracy: 1,
    );

    setState(() {
      _userPosition = position;
      _originController.text = "Lokasi Saya (Medan)";
      _mapController.move(LatLng(position.latitude, position.longitude), 14);
    });
  }

  Future<void> _fetchSmartRoutes() async {
    setState(() {
      _isLoading = true;
      _currentPolyline = []; 
    });
    try {
      String url = "${ApiService().baseUrl}/recommendations";
      if (_userPosition != null) {
        url += "?lat=${_userPosition!.latitude}&lng=${_userPosition!.longitude}";
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _recommendations = data;
        });

        // OTOMATIS: Gambar rute pertama yang dikirim dari JSON Anda
        if (_recommendations.isNotEmpty && _recommendations[0]['geometry'] != null) {
          _drawRoute(_recommendations[0]['geometry']);
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // FUNGSI INILAH YANG MENGUBAH JSON ANDA MENJADI GARIS
  void _drawRoute(dynamic geometry) {
    if (geometry == null || geometry is! List || geometry.isEmpty) return;

    List<LatLng> points = [];
    for (var coord in geometry) {
      // JSON Anda: [Longitude, Latitude]
      // Flutter Map: LatLng(Latitude, Longitude)
      points.add(LatLng(
        (coord[1] as num).toDouble(), 
        (coord[0] as num).toDouble()
      ));
    }

    setState(() {
      _currentPolyline = points;
    });

    // Zoom ke rute agar terlihat semua
    if (points.isNotEmpty) {
      _mapController.move(points[points.length ~/ 2], 13.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text("Navigasi Pintar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. MAP
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(3.5952, 98.6722),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/${ApiService.mapboxTrafficStyle}/tiles/256/{z}/{x}/{y}@2x?access_token=${ApiService.mapboxToken}',
                userAgentPackageName: 'com.medanflow.app',
              ),
              // --- INI ADALAH LAYER GARIS RUTE ---
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _currentPolyline,
                    color: Colors.deepOrange, 
                    strokeWidth: 6,
                    // Garis rute terlihat lebih smooth di ujungnya
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                ],
              ),
              if (_userPosition != null)
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                    width: 40, height: 40,
                    child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                  )
                ]),
            ],
          ),

          // 2. SEARCH CARD
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15)]),
              child: Column(
                children: [
                  _buildSearchInput(Icons.my_location, "Asal", _originController, Colors.blue),
                  const Padding(padding: EdgeInsets.only(left: 35), child: Divider(height: 20)),
                  _buildSearchInput(Icons.location_on, "Tujuan", _destController, Colors.red),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _fetchSmartRoutes,
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("ANALISIS JALUR TERCEPAT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),

          // 3. ZOOM CONTROLS
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height * 0.4,
            child: Column(
              children: [
                _buildMapActionBtn(Icons.add, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
                const SizedBox(height: 10),
                _buildMapActionBtn(Icons.remove, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
                const SizedBox(height: 10),
                _buildMapActionBtn(Icons.my_location, _determinePosition),
              ],
            ),
          ),

          // 4. PANEL HASIL
          _buildDraggableResults(),
        ],
      ),
    );
  }

  Widget _buildMapActionBtn(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
      child: IconButton(icon: Icon(icon, color: primaryColor, size: 22), onPressed: onTap),
    );
  }

  Widget _buildSearchInput(IconData icon, String hint, TextEditingController ctrl, Color color) {
    return Row(children: [Icon(icon, size: 20, color: color), const SizedBox(width: 15), Expanded(child: TextField(controller: ctrl, readOnly: true, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: hint)))]);
  }

  Widget _buildDraggableResults() {
    return DraggableScrollableSheet(
      initialChildSize: 0.15, minChildSize: 0.15, maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)]),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text("Opsi Rute Terbaik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              Expanded(
                child: _recommendations.isEmpty
                ? const Center(child: Text("Silakan cari rute di atas"))
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _recommendations.length,
                    itemBuilder: (context, index) {
                      final item = _recommendations[index];
                      return InkWell(
                        onTap: () => _drawRoute(item['geometry']), // Klik card rute untuk gambar di peta
                        child: _buildRouteCard(item),
                      );
                    },
                  ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)]),
      child: Row(
        children: [
          Column(children: [Text(item['eta']?.split(" ")[0] ?? "0", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF00796B))), const Text("MENIT", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))]),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['name'] ?? "Rute Medan", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text("Optimasi Jalur AI", style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 10),
            Text("📍 ${item['distance']}", style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold)),
          ])),
          const Icon(Icons.directions, color: Colors.blue),
        ],
      ),
    );
  }
}