import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────
class _P {
  static const b50 = Color(0xFFEFF6FF);
  static const b100 = Color(0xFFDBEAFE);
  static const b200 = Color(0xFFBFDBFE);
  static const b500 = Color(0xFF3B82F6);
  static const b600 = Color(0xFF2563EB);
  static const b700 = Color(0xFF1D4ED8);
  static const b800 = Color(0xFF1E40AF);
  static const bg = Color(0xFFEEF4FF);
  static const card = Colors.white;
  static const ink = Color(0xFF0F172A);
  static const ink3 = Color(0xFF64748B);
  static const dark = Color(0xFF0F2878);
}

class TravelTimePredictionScreen extends StatefulWidget {
  const TravelTimePredictionScreen({super.key});

  @override
  State<TravelTimePredictionScreen> createState() =>
      _TravelTimePredictionScreenState();
}

class _TravelTimePredictionScreenState extends State<TravelTimePredictionScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ───────────────────────────────────────
  final MapController _mapController = MapController();

  // ── Constants ─────────────────────────────────────────
  static const _medanCenter = LatLng(3.5952, 98.6722);

  // ── State ─────────────────────────────────────────────
  /// 0 = pilih asal, 1 = pilih tujuan, 2 = tampilkan hasil
  int _step = 0;
  bool _isLoading = false;

  LatLng? _originPoint;
  LatLng? _destPoint;
  Map<String, dynamic>? _predictionData;
  List<LatLng> _routePoints = [];

  /// ⚡ FIX: Tidak pakai setState — hanya di-update saat tombol diklik
  LatLng _currentMapCenter = _medanCenter;

  // ── Lifecycle ─────────────────────────────────────────
  @override
  void dispose() {
    _mapController.dispose(); // ⚡ FIX: Dispose untuk hindari memory leak
    super.dispose();
  }

  // ── Business Logic ────────────────────────────────────
  Future<void> _calculateRoute() async {
    if (_originPoint == null || _destPoint == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService().getTravelPrediction(
        _originPoint!.latitude,
        _originPoint!.longitude,
        _destPoint!.latitude,
        _destPoint!.longitude,
      );

      if (response != null && mounted) {
        final List<LatLng> points = [];
        if (response['route_geometry'] != null) {
          for (final point in response['route_geometry']) {
            points.add(LatLng(point[1] as double, point[0] as double));
          }
        } else {
          points.addAll([_originPoint!, _destPoint!]);
        }

        setState(() {
          _predictionData = response;
          _routePoints = points;
          _step = 2;
        });

        // Fit kamera ke tengah rute
        _mapController.move(
          LatLng(
            (_originPoint!.latitude + _destPoint!.latitude) / 2,
            (_originPoint!.longitude + _destPoint!.longitude) / 2,
          ),
          13.5,
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menganalisis rute. Cek koneksi ke server.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmStep() {
    if (_step == 0) {
      setState(() {
        _originPoint = _currentMapCenter;
        _step = 1;
      });
    } else if (_step == 1) {
      _destPoint = _currentMapCenter;
      _calculateRoute();
    }
  }

  void _resetScreen() {
    setState(() {
      _step = 0;
      _originPoint = null;
      _destPoint = null;
      _predictionData = null;
      _routePoints = [];
    });
    _mapController.move(_medanCenter, 15.0);
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildMap(),
          if (_step < 2) _buildCenterPin(),
          if (_step < 2) _buildInfoCard(),
          if (_step < 2) _buildActionButton(),
          if (_step == 2 && _predictionData != null) _buildResultSheet(),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _GlassButton(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, size: 16, color: _P.b600),
        ),
      ),
      title: _step < 2
          ? null
          : ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [_P.b600, Color(0xFF06B6D4)],
              ).createShader(b),
              child: const Text(
                'Hasil Analisis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ),
    );
  }

  // ── Map ───────────────────────────────────────────────
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _medanCenter,
        initialZoom: 15.0,
        // ⚡ FIX: Hapus setState — update variabel biasa saja
        onPositionChanged: (position, hasGesture) {
          if (hasGesture && _step < 2 && position.center != null) {
            _currentMapCenter = position.center!;
          }
        },
      ),
      children: [
        // ⚡ FIX: Hapus @2x, hapus additionalOptions yg redundan,
        //         tambah keepBuffer & zoom limits
        TileLayer(
          urlTemplate:
              'https://api.mapbox.com/styles/v1/mapbox/streets-v12'
              '/tiles/256/{z}/{x}/{y}?access_token=${ApiService.mapboxToken}',
          userAgentPackageName: 'com.medanflow.app',
          keepBuffer: 4, // tile tetap di-cache saat scroll
          maxNativeZoom: 18,
          minNativeZoom: 10,
          tileSize: 256,
        ),

        // Polyline rute
        if (_step == 2 && _routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                color: _P.b500,
                strokeWidth: 5.0,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
            ],
          ),

        // Marker asal & tujuan
        MarkerLayer(
          markers: [
            if (_originPoint != null)
              _buildMarker(
                point: _originPoint!,
                color: _P.b600,
                icon: Icons.my_location_rounded,
              ),
            if (_destPoint != null && _step == 2)
              _buildMarker(
                point: _destPoint!,
                color: const Color(0xFFDC2626),
                icon: Icons.flag_rounded,
              ),
          ],
        ),
      ],
    );
  }

  Marker _buildMarker({
    required LatLng point,
    required Color color,
    required IconData icon,
  }) {
    return Marker(
      point: point,
      width: 45,
      height: 45,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.40),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  // ── Center Pin ────────────────────────────────────────
  Widget _buildCenterPin() {
    final isOrigin = _step == 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _P.ink.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _P.b800.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                isOrigin ? 'Titik Keberangkatan' : 'Titik Tujuan Perjalanan',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isOrigin ? _P.b600 : const Color(0xFFEA580C))
                        .withOpacity(0.40),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: isOrigin ? _P.b500 : const Color(0xFFEA580C),
                size: 52,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Info Card (atas peta) ─────────────────────────────
  Widget _buildInfoCard() {
    final isOrigin = _step == 0;
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _P.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _P.b100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _P.b500.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOrigin
                      ? [_P.b50, _P.b100]
                      : [const Color(0xFFFFF7ED), const Color(0xFFFED7AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isOrigin ? Icons.my_location_rounded : Icons.flag_rounded,
                color: isOrigin ? _P.b600 : const Color(0xFFEA580C),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOrigin
                        ? 'Tentukan Lokasi Asal'
                        : 'Tentukan Lokasi Tujuan',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: _P.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Geser peta untuk memposisikan pin',
                    style: TextStyle(
                      color: _P.ink3,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _P.b50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _P.b100, width: 1),
              ),
              child: Text(
                '${_step + 1}/2',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _P.b600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Action Button ─────────────────────────────────────
  Widget _buildActionButton() {
    return Positioned(
      bottom: 40,
      left: 24,
      right: 24,
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: EdgeInsets.zero,
          ),
          onPressed: _isLoading ? null : _confirmStep,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_P.b500, _P.b700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _P.b600.withOpacity(0.40),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _step == 0
                          ? 'KONFIRMASI ASAL'
                          : 'ANALISIS ESTIMASI WAKTU',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Result Sheet ──────────────────────────────────────
  Widget _buildResultSheet() {
    final data = _predictionData!;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: _P.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A2563EB),
              blurRadius: 32,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _P.b100,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header gradient banner
            Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_P.b600, _P.b800, _P.dark],
                  stops: [0.0, 0.55, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: _P.b600.withOpacity(0.30),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ESTIMASI PERJALANAN',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['predicted_time'] as String? ?? '-',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.20)),
                    ),
                    child: Text(
                      (data['congestion_level'] as String? ?? '').toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(
                          data['status_color'] as String? ?? 'green',
                        ),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3 stat cards
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  _buildStatCard(
                    Icons.route_outlined,
                    'Jarak',
                    data['distance'] as String? ?? '-',
                    [_P.b50, _P.b100],
                    _P.b500,
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    Icons.cloud_queue_rounded,
                    'Cuaca',
                    (data['prediction_factors']
                                as Map<String, dynamic>?)?['weather']
                            as String? ??
                        '-',
                    [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
                    const Color(0xFF0EA5E9),
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    Icons.timer_outlined,
                    'Delay',
                    data['delay'] as String? ?? '-',
                    [const Color(0xFFFFF7ED), const Color(0xFFFED7AA)],
                    const Color(0xFFEA580C),
                  ),
                ],
              ),
            ),

            // Reset button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _P.b600,
                    side: const BorderSide(color: _P.b200, width: 1.5),
                    backgroundColor: _P.b50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _resetScreen,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: _P.b600,
                  ),
                  label: const Text(
                    'CARI RUTE LAIN',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: _P.b600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ────────────────────────────────────
  Widget _buildStatCard(
    IconData icon,
    String label,
    String value,
    List<Color> bgColors,
    Color iconColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: _P.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _P.b100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _P.b500.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: bgColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: _P.ink3,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: _P.ink,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String colorName) {
    switch (colorName) {
      case 'red':
        return const Color(0xFFDC2626);
      case 'orange':
        return const Color(0xFFEA580C);
      case 'blue':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF16A34A);
    }
  }
}

// ─────────────────────────────────────────────
// Reusable glass-style back button
// ─────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
