import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class TrafficHeatmapScreen extends StatefulWidget {
  const TrafficHeatmapScreen({super.key});

  @override
  State<TrafficHeatmapScreen> createState() => _TrafficHeatmapScreenState();
}

class _TrafficHeatmapScreenState extends State<TrafficHeatmapScreen> {
  final MapController _mapController = MapController();
  double _predictionMinutes = 5.0;
  List<CircleMarker> _circles = [];
  bool _isLoading = false;

  final Color primaryColor = const Color(0xFF00796B);

  @override
  void initState() {
    super.initState();
    _fetchHeatmapData();
  }

  Future<void> _fetchHeatmapData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("${ApiService().baseUrl}/traffic-heatmap?minutes=${_predictionMinutes.toInt()}"),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['data'];
        _generateCircles(data);
      }
    } catch (e) {
      debugPrint("Heatmap Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _generateCircles(List data) {
    List<CircleMarker> newCircles = [];
    for (var item in data) {
      // Warna heatmap dengan transparansi agar terlihat modern
      Color circleColor;
      if (item['congestion_level'] == 'macet') {
        circleColor = Colors.red.withOpacity(0.5);
      } else if (item['congestion_level'] == 'padat') {
        circleColor = Colors.orange.withOpacity(0.5);
      } else {
        circleColor = Colors.green.withOpacity(0.4);
      }

      newCircles.add(
        CircleMarker(
          point: LatLng(double.parse(item['lat'].toString()), double.parse(item['lng'].toString())),
          radius: double.parse(item['radius'].toString()),
          useRadiusInMeter: true,
          color: circleColor,
          borderStrokeWidth: 0,
        ),
      );
    }
    setState(() => _circles = newCircles);
  }

  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Prediksi Kemacetan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white.withOpacity(0.85),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. Peta Latar Belakang
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(3.5952, 98.6722),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.medanflow.app',
              ),
              CircleLayer(circles: _circles),
            ],
          ),

          // 2. Map Legend (Top Left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 20,
            child: _buildLegend(),
          ),

          // 3. Zoom Controls (Center Right)
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height * 0.35,
            child: Column(
              children: [
                _buildMapButton(Icons.add, _zoomIn),
                const SizedBox(height: 10),
                _buildMapButton(Icons.remove, _zoomOut),
              ],
            ),
          ),

          // 4. Prediction Control Panel (Bottom)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildPredictionPanel(),
          ),

          // Loading Overlay
          if (_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      SizedBox(width: 10),
                      Text("Menganalisis data...", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10)],
      ),
      child: IconButton(icon: Icon(icon, color: primaryColor), onPressed: onTap),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendItem(Colors.red, "Macet Parah"),
          const SizedBox(height: 5),
          _legendItem(Colors.orange, "Padat Merayap"),
          const SizedBox(height: 5),
          _legendItem(Colors.green, "Lancar"),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPredictionPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Prediksi Trafik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Berdasarkan AI & Data Historis", style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  "+${_predictionMinutes.toInt()} Menit",
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryColor,
              inactiveTrackColor: primaryColor.withOpacity(0.1),
              thumbColor: primaryColor,
              overlayColor: primaryColor.withOpacity(0.2),
              trackHeight: 6,
            ),
            child: Slider(
              value: _predictionMinutes,
              min: 5,
              max: 30,
              divisions: 5,
              onChanged: (v) => setState(() => _predictionMinutes = v),
              onChangeEnd: (v) => _fetchHeatmapData(),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Sekarang", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text("30 Mnt Ke Depan", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}