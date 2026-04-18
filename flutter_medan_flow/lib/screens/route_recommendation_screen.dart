import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────
// Palette (Profesional Medan Flow)
// ─────────────────────────────────────────────
class _P {
  static const b50 = Color(0xFFEFF6FF);
  static const b100 = Color(0xFFDBEAFE);
  static const b200 = Color(0xFFBFDBFE);
  static const b300 = Color(0xFF93C5FD);
  static const b400 = Color(0xFF60A5FA);
  static const b500 = Color(0xFF3B82F6);
  static const b600 = Color(0xFF2563EB);
  static const b700 = Color(0xFF1D4ED8);
  static const b800 = Color(0xFF1E40AF);
  static const bg = Color(0xFFEEF4FF);
  static const card = Colors.white;
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF334155);
  static const ink3 = Color(0xFF64748B);
  static const ink4 = Color(0xFF94A3B8);
}

class RouteRecommendationScreen extends StatefulWidget {
  const RouteRecommendationScreen({super.key});

  @override
  State<RouteRecommendationScreen> createState() =>
      _RouteRecommendationScreenState();
}

class _RouteRecommendationScreenState extends State<RouteRecommendationScreen> {
  final ApiService _apiService = ApiService();

  // Gunakan Completer agar move() hanya dipanggil setelah map siap
  final Completer<MapController> _mapControllerCompleter = Completer();
  MapController? _mapController;

  List _recommendations = [];
  bool _isLoading = false;

  final TextEditingController _originController = TextEditingController(
    text: 'Mendeteksi lokasi...',
  );
  final TextEditingController _destController = TextEditingController(
    text: 'Pinang Baris',
  );

  // Posisi default Medan langsung di sini, tidak perlu tunggu GPS
  static const LatLng _defaultCenter = LatLng(3.5952, 98.6722);
  Position? _userPosition;
  List<LatLng> _currentPolyline = [];
  int? _selectedRouteIndex;

  @override
  void initState() {
    super.initState();
    _setDefaultPosition();
  }

  // Set posisi Medan secara synchronous supaya marker langsung muncul
  void _setDefaultPosition() {
    final position = Position(
      latitude: _defaultCenter.latitude,
      longitude: _defaultCenter.longitude,
      timestamp: DateTime.now(),
      accuracy: 1,
      altitude: 1,
      heading: 1,
      speed: 1,
      speedAccuracy: 1,
      altitudeAccuracy: 1,
      headingAccuracy: 1,
    );
    _userPosition = position;
    _originController.text = 'Lokasi Saya (Medan)';
  }

  // Dipanggil setelah map siap (dari tombol my_location)
  Future<void> _determinePosition() async {
    setState(() => _originController.text = 'Mendeteksi GPS...');

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        if (!mounted) return;
        setState(() {
          _userPosition = position;
          _originController.text = 'Lokasi Saya Saat Ini';
        });

        // Safe move via completer
        final ctrl = await _mapControllerCompleter.future;
        ctrl.move(LatLng(position.latitude, position.longitude), 14);
      } else {
        if (mounted)
          setState(() => _originController.text = 'Izin GPS Ditolak');
      }
    } catch (e) {
      debugPrint('GPS error: $e');
      if (mounted)
        setState(() => _originController.text = 'Lokasi Saya (Medan)');
    }
  }

  Future<void> _fetchSmartRoutes() async {
    setState(() {
      _isLoading = true;
      _currentPolyline = [];
      _selectedRouteIndex = null;
    });
    try {
      String url = '${_apiService.baseUrl}/recommendations';
      if (_userPosition != null) {
        url +=
            '?lat=${_userPosition!.latitude}&lng=${_userPosition!.longitude}';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _recommendations = data;
          _selectedRouteIndex = data.isNotEmpty ? 0 : null;
        });
        if (_recommendations.isNotEmpty &&
            _recommendations[0]['geometry'] != null) {
          _drawRoute(_recommendations[0]['geometry'], index: 0);
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _drawRoute(dynamic geometry, {int? index}) {
    if (geometry == null || geometry is! List || geometry.isEmpty) return;
    final List<LatLng> points = [
      for (var coord in geometry)
        LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble()),
    ];
    setState(() {
      _currentPolyline = points;
      if (index != null) _selectedRouteIndex = index;
    });
    if (points.isNotEmpty && _mapController != null) {
      _mapController!.move(points[points.length ~/ 2], 13.0);
    }
  }

  // Safe move helper
  void _safeMove(LatLng center, double zoom) {
    if (_mapControllerCompleter.isCompleted && _mapController != null) {
      _mapController!.move(center, zoom);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD UTAMA
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: _P.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _P.b100, width: 1.5),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: _P.b600,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Navigasi Pintar',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _P.ink,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ── Peta ──────────────────────────────────────────────────────────
          FlutterMap(
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 14,
              onMapReady: () {
                if (!_mapControllerCompleter.isCompleted) {
                  _mapControllerCompleter.complete(_mapController);
                }
              },
            ),
            children: [
              TileLayer(
                // Tanpa @2x agar tile lebih kecil & cepat dimuat
                urlTemplate:
                    'https://api.mapbox.com/styles/v1/${ApiService.mapboxTrafficStyle}/tiles/256/{z}/{x}/{y}?access_token=${ApiService.mapboxToken}',
                userAgentPackageName: 'com.medanflow.app',
                maxNativeZoom: 18,
                keepBuffer: 4,
              ),
              PolylineLayer(
                polylines: [
                  if (_currentPolyline.isNotEmpty)
                    Polyline(
                      points: _currentPolyline,
                      color: _P.b500,
                      strokeWidth: 5.5,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                ],
              ),
              if (_userPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _userPosition!.latitude,
                        _userPosition!.longitude,
                      ),
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _P.b600,
                          boxShadow: [
                            BoxShadow(
                              color: _P.b600.withOpacity(0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Search Card ───────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 66,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _P.card,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(color: _P.b500.withOpacity(0.1), blurRadius: 16),
                ],
              ),
              child: Column(
                children: [
                  _buildSearchInput(
                    Icons.my_location_rounded,
                    'Asal',
                    _originController,
                    _P.b600,
                  ),
                  const Divider(height: 24),
                  _buildSearchInput(
                    Icons.flag_rounded,
                    'Tujuan',
                    _destController,
                    Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _fetchSmartRoutes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _P.b600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'ANALISIS JALUR TERCEPAT',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Zoom Controls ─────────────────────────────────────────────────
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.42,
            child: Column(
              children: [
                _buildMapActionBtn(
                  Icons.add_rounded,
                  () => _safeMove(
                    _mapController?.camera.center ?? _defaultCenter,
                    (_mapController?.camera.zoom ?? 14) + 1,
                  ),
                ),
                const SizedBox(height: 8),
                _buildMapActionBtn(
                  Icons.remove_rounded,
                  () => _safeMove(
                    _mapController?.camera.center ?? _defaultCenter,
                    (_mapController?.camera.zoom ?? 14) - 1,
                  ),
                ),
                const SizedBox(height: 8),
                _buildMapActionBtn(
                  Icons.my_location_rounded,
                  _determinePosition,
                  accent: true,
                ),
              ],
            ),
          ),

          // ── Draggable Results ─────────────────────────────────────────────
          _buildDraggableResults(),
        ],
      ),
    );
  }

  // ── Widget Helpers ─────────────────────────────────────────────────────────

  Widget _buildMapActionBtn(
    IconData icon,
    VoidCallback onTap, {
    bool accent = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: accent ? _P.b600 : _P.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: IconButton(
        icon: Icon(icon, color: accent ? Colors.white : _P.b600),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildSearchInput(
    IconData icon,
    String hint,
    TextEditingController ctrl,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: ctrl,
            readOnly: true,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: hint,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableResults() {
    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.15,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _P.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _P.b100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'OPSI RUTE TERBAIK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _P.ink2,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (_recommendations.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _P.b50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _P.b100),
                        ),
                        child: Text(
                          '${_recommendations.length} Rute',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: _P.b600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(height: 1, color: _P.b50),
              // Content
              Expanded(
                child: _recommendations.isEmpty
                    ? SingleChildScrollView(
                        controller: scrollController,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 10),
                              Icon(
                                Icons.alt_route_rounded,
                                color: _P.b300,
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Cari rute di atas',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _P.ink3,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: _recommendations.length,
                        itemBuilder: (context, index) {
                          final item = _recommendations[index];
                          return _buildRouteCard(item, index);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> item, int index) {
    final isSelected = _selectedRouteIndex == index;
    return GestureDetector(
      onTap: () => _drawRoute(item['geometry'], index: index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _P.b50 : _P.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _P.b400 : _P.b100),
          boxShadow: [
            BoxShadow(
              color: _P.b500.withOpacity(isSelected ? 0.12 : 0.05),
              blurRadius: isSelected ? 14 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // ETA badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [_P.b500, _P.b700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [_P.b50, _P.b100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _P.b600.withOpacity(0.30),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Text(
                    item['eta']?.split(' ')[0] ?? '0',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : _P.b600,
                    ),
                  ),
                  Text(
                    'MENIT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white.withOpacity(0.75)
                          : _P.ink4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? 'Rute Medan',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    item['distance']?.toString() ?? '-',
                    style: const TextStyle(fontSize: 12, color: _P.ink3),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.directions_rounded,
              color: isSelected ? _P.b600 : _P.b400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
