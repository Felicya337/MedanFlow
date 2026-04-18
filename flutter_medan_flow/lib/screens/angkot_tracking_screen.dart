import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Palette & Styling (Konsisten dengan Tema Profesional Medan Flow)
// ─────────────────────────────────────────────────────────────────────────────
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
  static const card = Colors.white;
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF1E293B);
  static const ink3 = Color(0xFF64748B);
  static const ink4 = Color(0xFF94A3B8);
  static const dark = Color(0xFF0F2878);
}

class AngkotTrackingScreen extends StatefulWidget {
  const AngkotTrackingScreen({super.key});

  @override
  State<AngkotTrackingScreen> createState() => _AngkotTrackingScreenState();
}

class _AngkotTrackingScreenState extends State<AngkotTrackingScreen>
    with SingleTickerProviderStateMixin {
  // ── Kontroler & Data ───────────────────────────────────────────────────────
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  List<Marker> _markers = [];
  Timer? _timer;
  bool _isLoading = true;
  bool _mapReady = false;
  List<dynamic> _angkotList = [];
  LatLng _initialCameraCenter = const LatLng(
    3.5952,
    98.6722,
  ); // Default Medan jika GPS gagal

  // ── Animasi Orb (Visual Pulse pada Marker) ─────────────────────────────────
  late AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _initTracking();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  // Gabungan inisialisasi data dan lokasi user
  Future<void> _initTracking() async {
    await _determineUserPosition(); // Cari lokasi user dulu
    _fetchData(); // Ambil data angkot
    // Refresh posisi angkot setiap 10 detik agar tetap sinkron dengan GPS asli Driver
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _orbCtrl.dispose();
    super.dispose();
  }

  // FUNGSI UTAMA: Mendeteksi Lokasi Asli Tanpa Cheat
  Future<void> _determineUserPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Ambil posisi asli perangkat
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (mounted) {
      setState(() {
        _initialCameraCenter = LatLng(position.latitude, position.longitude);
      });
      // Gerakkan peta ke lokasi user saat ini secara otomatis
      _mapController.move(_initialCameraCenter, 14.0);
    }
  }

  // ── Logika Pengambilan Data Angkot ────────────────────────────────────────
  Future<void> _fetchData() async {
    try {
      final data = await _apiService.getActiveAngkots();
      if (mounted) {
        setState(() {
          _angkotList = data;
          _isLoading = false;
        });
        _updateMarkers(data);
      }
    } catch (e) {
      debugPrint('Tracking Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Pembuatan Marker Berwarna Dinamis ──────────────────────────────────────
  void _updateMarkers(List<dynamic> data) {
    final newMarkers = <Marker>[];
    for (final angkot in data) {
      final isFull = angkot['crowd_status'] == 'Penuh';
      final statusColor = isFull ? const Color(0xFFDC2626) : _P.b600;

      newMarkers.add(
        Marker(
          point: LatLng(
            double.parse(angkot['latitude'].toString()),
            double.parse(angkot['longitude'].toString()),
          ),
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () => _focusOnAngkot(angkot),
            child: AnimatedBuilder(
              animation: _orbCtrl,
              builder: (context, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        angkot['angkot_number'],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 30 + (15 * _orbCtrl.value),
                          height: 30 + (15 * _orbCtrl.value),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor.withOpacity(
                              0.2 * (1 - _orbCtrl.value),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.directions_bus_rounded,
                          color: statusColor,
                          size: 28,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    }
    if (mounted) setState(() => _markers = newMarkers);
  }

  void _focusOnAngkot(dynamic angkot) {
    _mapController.move(
      LatLng(
        double.parse(angkot['latitude'].toString()),
        double.parse(angkot['longitude'].toString()),
      ),
      15.0,
    );
  }

  void _zoomIn() => _mapController.move(
    _mapController.camera.center,
    _mapController.camera.zoom + 1,
  );

  void _zoomOut() => _mapController.move(
    _mapController.camera.center,
    _mapController.camera.zoom - 1,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. LAYER PETA (OSM) ───────────────────────────────────────────────
          _buildMap(),

          // 2. SKELETON OVERLAY (tampil hingga peta siap) ─────────────────────
          if (!_mapReady) _buildMapSkeleton(),

          // 3. ZOOM & MY LOCATION CONTROLS ────────────────────────────────────
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.35,
            child: Column(
              children: [
                _buildMapActionBtn(Icons.add_rounded, _zoomIn),
                const SizedBox(height: 8),
                _buildMapActionBtn(Icons.remove_rounded, _zoomOut),
                const SizedBox(height: 8),
                _buildMapActionBtn(
                  Icons.my_location_rounded,
                  _determineUserPosition,
                  accent: true,
                ),
              ],
            ),
          ),

          // 4. DRAGGABLE LIST PANEL ───────────────────────────────────────────
          _buildDraggableAngkotList(),

          // 5. HEADER OVERLAY (Paling atas agar Tombol Back bisa ditekan) ──────
          Positioned(top: 0, left: 0, right: 0, child: _buildHeader()),

          // 6. SUBTLE LOADING SPINNER (setelah peta siap) ─────────────────────
          if (_isLoading && _mapReady)
            Positioned(
              top: MediaQuery.of(context).padding.top + 100,
              right: 70,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: _P.b500.withOpacity(0.15), blurRadius: 10),
                  ],
                ),
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: _P.b600,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Map ────────────────────────────────────────────────────────────────────
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _initialCameraCenter,
        initialZoom: 13,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onMapReady: () {
          if (mounted) setState(() => _mapReady = true);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.medanflow.app',
          tileProvider: CancellableNetworkTileProvider(),
          maxNativeZoom: 19,
          panBuffer: 0,
          keepBuffer: 2,
          tileDisplay: const TileDisplay.fadeIn(
            duration: Duration(milliseconds: 150),
            startOpacity: 0.6,
          ),
          errorTileCallback: (tile, error, stackTrace) {
            debugPrint('Tile error: $error');
          },
        ),
        MarkerLayer(markers: _markers, rotate: false),
      ],
    );
  }

  // ── Map Skeleton ───────────────────────────────────────────────────────────
  Widget _buildMapSkeleton() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _orbCtrl,
        builder: (_, __) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFCFDDEE),
                  Color.lerp(
                    const Color(0xFFBDCEE2),
                    const Color(0xFFD8E6F3),
                    _orbCtrl.value,
                  )!,
                  const Color(0xFFCFDDEE),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.map_outlined,
                      size: 28,
                      color: _P.b600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Memuat peta…',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _P.b700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: null,
                        backgroundColor: _P.b200,
                        color: _P.b600,
                        minHeight: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_P.b600, _P.b800, _P.dark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _P.b600.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Material(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Tracking Angkot',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'Sinkronisasi GPS setiap 10 detik',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _buildLiveBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF4ADE80),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'LIVE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tombol Kontrol Peta ────────────────────────────────────────────────────
  Widget _buildMapActionBtn(
    IconData icon,
    VoidCallback onTap, {
    bool accent = false,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: accent ? _P.b600 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.b100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _P.b500.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: accent ? Colors.white : _P.b600, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildDraggableAngkotList() {
    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.10,
      maxChildSize: 0.75,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A1D4ED8),
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _P.b200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ARMADA AKTIF',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: _P.ink,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _P.b50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _P.b100),
                      ),
                      child: Text(
                        '${_angkotList.length} Unit',
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
              Container(height: 1, color: _P.b100),
              const SizedBox(height: 4),
              Expanded(
                child: _angkotList.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
                        itemCount: _angkotList.length,
                        itemBuilder: (context, index) =>
                            _buildAngkotCard(_angkotList[index]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAngkotCard(dynamic angkot) {
    final isFull = angkot['crowd_status'] == 'Penuh';
    final accentColor = isFull ? const Color(0xFFDC2626) : _P.b600;
    final accentBg = isFull ? const Color(0xFFFEF2F2) : _P.b50;

    return GestureDetector(
      onTap: () => _focusOnAngkot(angkot),
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _P.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _P.b100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _P.b500.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accentColor.withOpacity(0.20),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.directions_bus_filled_rounded,
                color: accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Angkot ${angkot['angkot_number']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _P.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    angkot['route_name'] ?? 'Rute Medan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: _P.ink3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildStatusBadge(angkot['crowd_status']),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.timer_outlined,
                        size: 12,
                        color: _P.ink4,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${angkot['eta_minutes']} Menit',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _P.ink2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _P.b50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: _P.b400,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isFull = status == 'Penuh';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isFull ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFull ? const Color(0xFFFECACA) : const Color(0xFF86EFAC),
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: isFull ? const Color(0xFFDC2626) : const Color(0xFF15803D),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _P.b50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.bus_alert_rounded,
              size: 36,
              color: _P.b300,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Tidak Ada Armada Aktif',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: _P.ink2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Belum ada driver yang sedang narik saat ini.',
            style: TextStyle(
              fontSize: 12,
              color: _P.ink4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
