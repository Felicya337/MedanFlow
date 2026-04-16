import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

// ─────────────────────────────────────────────
// Palette (Konsisten dengan Tema Medan Flow)
// ─────────────────────────────────────────────
class _P {
  static const b50 = Color(0xFFEFF6FF);
  static const b100 = Color(0xFFDBEAFE);
  static const b300 = Color(0xFF93C5FD);
  static const b400 = Color(0xFF60A5FA);
  static const b500 = Color(0xFF3B82F6);
  static const b600 = Color(0xFF2563EB);
  static const b700 = Color(0xFF1D4ED8);
  static const b800 = Color(0xFF1E40AF);
  static const bg = Color(0xFFEEF4FF);
  static const card = Colors.white;
  static const ink = Color(0xFF0F172A);
  static const ink3 = Color(0xFF64748B);
  static const ink4 = Color(0xFF94A3B8);
  static const dark = Color(0xFF0F2878);
}

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

  @override
  void initState() {
    super.initState();
    _fetchHeatmapData();
  }

  // ── Logic Data (Integrasi Backend) ──────────────────────────
  Future<void> _fetchHeatmapData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiService().baseUrl}/traffic-heatmap?minutes=${_predictionMinutes.toInt()}",
        ),
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
          point: LatLng(
            double.parse(item['lat'].toString()),
            double.parse(item['lng'].toString()),
          ),
          radius: double.parse(item['radius'].toString()),
          useRadiusInMeter: true,
          color: circleColor,
          borderStrokeWidth: 0,
        ),
      );
    }
    setState(() => _circles = newCircles);
  }

  void _zoomIn() => _mapController.move(
    _mapController.camera.center,
    _mapController.camera.zoom + 1,
  );

  void _zoomOut() => _mapController.move(
    _mapController.camera.center,
    _mapController.camera.zoom - 1,
  );

  // ════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── 1. Peta (MENGGUNAKAN MAPBOX TRAFFIC API) ────────
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(3.5952, 98.6722),
              initialZoom: 13,
            ),
            children: [
              // INTEGRASI MAPBOX LAYER
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/${ApiService.mapboxTrafficStyle}/tiles/256/{z}/{x}/{y}@2x?access_token=${ApiService.mapboxToken}',
                additionalOptions: const {
                  'accessToken': ApiService.mapboxToken,
                  'id': ApiService.mapboxTrafficStyle,
                },
                userAgentPackageName: 'com.medanflow.app',
              ),
              CircleLayer(circles: _circles),
            ],
          ),

          // ── 2. Header ──────────────────────────────────────
          Positioned(
            top: topPad + 12,
            left: 20,
            right: 20,
            child: _buildHeader(),
          ),

          // ── 3. Legend ──────────────────────────────────────
          Positioned(top: topPad + 80, left: 20, child: _buildLegend()),

          // ── 4. Zoom Controls ───────────────────────────────
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height * 0.38,
            child: _buildZoomControls(),
          ),

          // ── 5. Prediction Panel ────────────────────────────
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildPredictionPanel(),
          ),

          // ── 6. Loading Indicator ───────────────────────────
          if (_isLoading)
            Positioned(
              top: topPad + 80,
              left: 0,
              right: 0,
              child: Center(child: _buildLoadingChip()),
            ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.b100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _P.b500.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _P.b50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _P.b100, width: 1.5),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _P.b600,
                size: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [_P.b600, Color(0xFF06B6D4)],
                  ).createShader(b),
                  child: const Text(
                    'Prediksi Kemacetan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const Text(
                  'Heatmap real-time Kota Medan',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: _P.ink3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _fetchHeatmapData,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_P.b500, _P.b700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _P.b600.withOpacity(0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Legend ───────────────────────────────────────────────────
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.b100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _P.b500.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LEGENDA',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: _P.ink4,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 7),
          _legendItem(Colors.red, 'Macet Parah'),
          const SizedBox(height: 5),
          _legendItem(Colors.orange, 'Padat Merayap'),
          const SizedBox(height: 5),
          _legendItem(Colors.green, 'Lancar'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withOpacity(0.85),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.40), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _P.ink,
          ),
        ),
      ],
    );
  }

  // ── Zoom Controls ─────────────────────────────────────────────
  Widget _buildZoomControls() {
    return Column(
      children: [
        _zoomBtn(Icons.add_rounded, _zoomIn),
        const SizedBox(height: 8),
        _zoomBtn(Icons.remove_rounded, _zoomOut),
      ],
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _P.b100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _P.b500.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: _P.b600, size: 20),
      ),
    );
  }

  // ── Loading Chip ──────────────────────────────────────────────
  Widget _buildLoadingChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_P.b600, _P.b800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _P.b600.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 9),
          Text(
            'Menganalisis data...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Prediction Panel ──────────────────────────────────────────
  Widget _buildPredictionPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _P.b100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _P.b500.withOpacity(0.14),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _P.b50,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: _P.b100, width: 1.5),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: _P.b600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prediksi Trafik',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: _P.ink,
                      ),
                    ),
                    Text(
                      'Berbasis AI & Data Historis',
                      style: TextStyle(
                        fontSize: 11,
                        color: _P.ink3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_P.b500, _P.b700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _P.b600.withOpacity(0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  '+${_predictionMinutes.toInt()} Mnt',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: _P.b100),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _P.b500,
              inactiveTrackColor: _P.b100,
              thumbColor: _P.b600,
              overlayColor: _P.b500.withOpacity(0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              trackHeight: 5,
            ),
            child: Slider(
              value: _predictionMinutes,
              min: 5,
              max: 30,
              divisions: 5,
              onChanged: (v) => setState(() => _predictionMinutes = v),
              onChangeEnd: (_) => _fetchHeatmapData(),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sekarang',
                  style: TextStyle(
                    fontSize: 10,
                    color: _P.ink4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '30 Mnt Ke Depan',
                  style: TextStyle(
                    fontSize: 10,
                    color: _P.ink4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}