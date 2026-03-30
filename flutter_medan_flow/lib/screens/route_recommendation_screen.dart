import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; 
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class RouteRecommendationScreen extends StatefulWidget {
  const RouteRecommendationScreen({super.key});

  @override
  State<RouteRecommendationScreen> createState() => _RouteRecommendationScreenState();
}

class _RouteRecommendationScreenState extends State<RouteRecommendationScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController(); // Controller untuk kontrol zoom
  List _recommendations = [];
  bool _isLoading = false;
  
  final TextEditingController _originController = TextEditingController(text: "Terminal Amplas");
  final TextEditingController _destController = TextEditingController(text: "Pinang Baris");

  Future<void> _fetchSmartRoutes() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("${_apiService.baseUrl}/recommendations"));
      if (response.statusCode == 200) {
        setState(() {
          _recommendations = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error Fetching Routes: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Fungsi untuk Zoom In
  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  // Fungsi untuk Zoom Out
  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00796B);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Cari Rute Terbaik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white.withOpacity(0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. BACKGROUND MAP
          FlutterMap(
            mapController: _mapController, // Pasang controller di sini
            options: const MapOptions(
              initialCenter: LatLng(3.5952, 98.6722),
              initialZoom: 13,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all, // Mengizinkan semua interaksi manual
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.medanflow.app',
              ),
            ],
          ),

          // 2. FLOATING SEARCH BAR
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  _buildSearchInput(Icons.circle_outlined, "Asal", _originController, Colors.blue),
                  const Padding(
                    padding: EdgeInsets.only(left: 35),
                    child: Divider(height: 20, thickness: 0.5),
                  ),
                  _buildSearchInput(Icons.location_on, "Tujuan", _destController, Colors.red),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _fetchSmartRoutes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("ANALISIS RUTE PINTAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),

          // 3. CUSTOM ZOOM CONTROLS (Floating on the Right)
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height * 0.45,
            child: Column(
              children: [
                _buildZoomButton(Icons.add, _zoomIn),
                const SizedBox(height: 10),
                _buildZoomButton(Icons.remove, _zoomOut),
              ],
            ),
          ),

          // 4. BOTTOM SHEET RESULTS
          _buildDraggableResults(),
        ],
      ),
    );
  }

  // Widget Helper untuk Tombol Zoom
  Widget _buildZoomButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 3))
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF00796B)),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSearchInput(IconData icon, String label, TextEditingController controller, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 15),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: label,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableResults() {
    return DraggableScrollableSheet(
      initialChildSize: 0.12,
      minChildSize: 0.12,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
              const Text("Rekomendasi Rute", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              
              Expanded(
                child: _recommendations.isEmpty
                ? const Center(child: Text("Silakan cari rute terlebih dahulu", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _recommendations.length,
                    itemBuilder: (context, index) {
                      final item = _recommendations[index];
                      return _buildRouteCard(item);
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
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(item['eta']?.split(" ")[0] ?? "0", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00796B))),
              const Text("MENIT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? "Rute Medan", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(item['path'] ?? "-", style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _statusBadge(item['congestion'] ?? "low"),
                    const SizedBox(width: 8),
                    Text("📍 ${item['distance']}", style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                )
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.green;
    String label = "Lancar";
    if (status == 'medium') { color = Colors.orange; label = "Padat"; }
    if (status == 'high') { color = Colors.red; label = "Macet"; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}