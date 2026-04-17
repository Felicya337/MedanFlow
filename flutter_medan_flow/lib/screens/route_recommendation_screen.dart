import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────
// Palette (sama persis dengan LandingPage)
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
  static const dark = Color(0xFF0F2878);
}

class RouteRecommendationScreen extends StatefulWidget {
  const RouteRecommendationScreen({super.key});

  @override
  State<RouteRecommendationScreen> createState() =>
      _RouteRecommendationScreenState();
}

class _RouteRecommendationScreenState extends State<RouteRecommendationScreen> {
  final ApiService _apiService = ApiService();

  // ── FIX 1: Gunakan Completer agar move() hanya dipanggil setelah map siap ──
  final Completer<MapController> _mapControllerCompleter = Completer();
  MapController? _mapController;

  List _recommendations = [];
  bool _isLoading = false;

  final TextEditingController _originController = TextEditingController(
    text: "Mendeteksi lokasi...",
  );
  final TextEditingController _destController = TextEditingController(
    text: "Pinang Baris",
  );

  // ── FIX 2: Posisi default Medan langsung di sini, tidak perlu tunggu GPS ──
  static const LatLng _defaultCenter = LatLng(3.5952, 98.6722);
  Position? _userPosition;
  List<LatLng> _currentPolyline = [];
  int? _selectedRouteIndex;

  @override
  void initState() {
    super.initState();
    // Langsung set posisi tanpa async/await di initState
    _setDefaultPosition();
  }

  /// Set posisi Medan secara synchronous supaya marker langsung muncul
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
    // Set state sebelum build → marker langsung ada saat peta muncul
    _userPosition = position;
    _originController.text = "Lokasi Saya (Medan)";
  }

  /// Dipanggil setelah map siap (dari onMapReady)
  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      // Cheat Emulator (Medan) – ganti dengan GPS asli jika perlu
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

      if (!mounted) return;
      setState(() {
        _userPosition = position;
        _originController.text = "Lokasi Saya (Medan)";
      });

      // FIX 3: Pakai safe move via completer
      final ctrl = await _mapControllerCompleter.future;
      ctrl.move(LatLng(position.latitude, position.longitude), 14);
    } catch (e) {
      debugPrint("GPS error: $e");
    }
  }

  Future<void> _fetchSmartRoutes() async {
    setState(() {
      _isLoading = true;
      _currentPolyline = [];
      _selectedRouteIndex = null;
    });
    try {
      String url = "${ApiService().baseUrl}/recommendations";
      if (_userPosition != null) {
        url +=
            "?lat=${_userPosition!.latitude}&lng=${_userPosition!.longitude}";
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
      debugPrint("Error: $e");
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

  // ── FIX 4: Safe move helper ───────────────────────────────────────────────
  void _safeMove(LatLng center, double zoom) {
    if (_mapControllerCompleter.isCompleted && _mapController != null) {
      _mapController!.move(center, zoom);
    }
  }

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
              boxShadow: [
                BoxShadow(
                  color: _P.b500.withOpacity(0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [_P.b600, Color(0xFF06B6D4)],
          ).createShader(b),
          child: const Text(
            'Navigasi Pintar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ── PETA ──────────────────────────────────────────────
          FlutterMap(
            options: MapOptions(
              // FIX 5: initialCenter & initialZoom langsung pakai default,
              // tidak ada async di sini → peta langsung render
              initialCenter: _defaultCenter,
              initialZoom: 14,
              // FIX 6: onMapReady menggantikan pola MapController lama
              onMapReady: () {
                // Resolve completer sehingga _mapController siap dipakai
                if (!_mapControllerCompleter.isCompleted) {
                  _mapControllerCompleter.complete(_mapController);
                }
              },
            ),
            // FIX 7: Pasang controller via MapOptions bukan konstruktor lama
            children: [
              // FIX 8: Hapus @2x agar tile lebih kecil & cepat dimuat;
              //         ganti retina=true dengan retina=false (default)
              TileLayer(
                urlTemplate:
                    'https://api.mapbox.com/styles/v1/${ApiService.mapboxTrafficStyle}/tiles/256/{z}/{x}/{y}?access_token=${ApiService.mapboxToken}',
                userAgentPackageName: 'com.medanflow.app',
                // FIX 9: Aktifkan keep alive & beri maxNativeZoom agar
                //         flutter_map tidak minta tile resolusi terlalu tinggi
                maxNativeZoom: 18,
                // FIX 10: Cache tile di memory supaya pan/zoom lebih smooth
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
                              color: _P.b600.withOpacity(0.40),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
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

          // ── SEARCH CARD ────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 66,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _P.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _P.b100, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _P.b500.withOpacity(0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSearchInput(
                    Icons.my_location_rounded,
                    "Asal",
                    _originController,
                    _P.b600,
                    [_P.b50, _P.b100],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(38, 6, 0, 6),
                    child: Row(
                      children: [
                        Container(width: 1.5, height: 18, color: _P.b200),
                      ],
                    ),
                  ),
                  _buildSearchInput(
                    Icons.flag_rounded,
                    "Tujuan",
                    _destController,
                    const Color(0xFFDC2626),
                    [const Color(0xFFFFF1F2), const Color(0xFFFFE4E6)],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _fetchSmartRoutes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_P.b500, _P.b700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _P.b600.withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "ANALISIS JALUR TERCEPAT",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── ZOOM CONTROLS ──────────────────────────────────────
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

          // ── DRAGGABLE RESULTS ──────────────────────────────────
          _buildDraggableResults(),
        ],
      ),
    );
  }

  Widget _buildMapActionBtn(
    IconData icon,
    VoidCallback onTap, {
    bool accent = false,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: accent ? _P.b600 : _P.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: accent ? _P.b500 : _P.b100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _P.b500.withOpacity(accent ? 0.30 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: accent ? Colors.white : _P.b600, size: 18),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildSearchInput(
    IconData icon,
    String hint,
    TextEditingController ctrl,
    Color iconColor,
    List<Color> bgColors,
  ) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: bgColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: ctrl,
            readOnly: true,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _P.ink,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(color: _P.ink4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableResults() {
    return DraggableScrollableSheet(
      initialChildSize: 0.13,
      minChildSize: 0.13,
      maxChildSize: 0.68,
      builder: (context, scrollController) {
        return Container(
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
            children: [
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
              Expanded(
                child: _recommendations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _P.b50,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.alt_route_rounded,
                                color: _P.b400,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Cari rute di atas',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _P.ink3,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        itemCount: _recommendations.length,
                        itemBuilder: (context, index) {
                          final item = _recommendations[index];
                          final isSelected = _selectedRouteIndex == index;
                          return GestureDetector(
                            onTap: () =>
                                _drawRoute(item['geometry'], index: index),
                            child: _buildRouteCard(item, isSelected, index),
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

  Widget _buildRouteCard(
    Map<String, dynamic> item,
    bool isSelected,
    int index,
  ) {
    final etaText = item['eta']?.toString().split(" ")[0] ?? "0";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? _P.b50 : _P.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? _P.b400 : _P.b100,
          width: isSelected ? 2 : 1.5,
        ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [_P.b500, _P.b700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
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
                  etaText,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : _P.b600,
                    height: 1.0,
                  ),
                ),
                Text(
                  'MENIT',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? Colors.white.withOpacity(0.75)
                        : _P.ink4,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? "Rute Medan",
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: _P.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      "Optimasi Jalur AI",
                      style: TextStyle(
                        fontSize: 11,
                        color: _P.ink3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.route_outlined, size: 13, color: _P.ink4),
                    const SizedBox(width: 4),
                    Text(
                      item['distance']?.toString() ?? "-",
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: _P.ink3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? _P.b600 : _P.b50,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.directions_rounded,
              color: isSelected ? Colors.white : _P.b400,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
