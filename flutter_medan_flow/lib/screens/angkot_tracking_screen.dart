import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────
// Palette
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
  static const card = Colors.white;
  static const ink = Color(0xFF0F172A);
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
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  List<Marker> _markers = [];
  Timer? _timer;
  bool _isLoading = true;
  bool _mapReady = false;
  List<dynamic> _angkotList = [];

  late AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchData());
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _orbCtrl.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────
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
      debugPrint('OSM Tracking Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
          width: 72,
          height: 72,
          child: GestureDetector(
            onTap: () => _focusOnAngkot(angkot),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    angkot['angkot_number'],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  Icons.directions_bus_rounded,
                  color: statusColor,
                  size: 30,
                  shadows: [
                    Shadow(color: statusColor.withOpacity(0.35), blurRadius: 8),
                  ],
                ),
              ],
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

  // ════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── 1. Map ─────────────────────────────────────────
          _buildMap(),

          // ── 2. Skeleton overlay (shown until map is ready)
          if (!_mapReady) _buildMapSkeleton(),

          // ── 3. Header ──────────────────────────────────────
          Positioned(top: 0, left: 0, right: 0, child: _buildHeader()),

          // ── 4. Zoom controls ───────────────────────────────
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.28,
            child: _buildZoomControls(),
          ),

          // ── 5. Draggable list ──────────────────────────────
          _buildDraggableAngkotList(),

          // ── 6. Subtle loading spinner after map ready
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

  // ── Map ──────────────────────────────────────────────────────
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(3.5952, 98.6722),
        initialZoom: 13,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        // FIX: Langsung set _mapReady tanpa Future.delayed
        // sehingga peta muncul secepat mungkin
        onMapReady: () {
          if (mounted) setState(() => _mapReady = true);
        },
      ),
      children: [
        // ── Tile layer ──────────────────────────────────────
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.medanflow.app',

          // FIX: CancellableTileProvider dari versi ^3.0.0
          tileProvider: CancellableNetworkTileProvider(),

          maxNativeZoom: 19,

          // FIX: panBuffer 0 = tidak pre-fetch tile di luar viewport
          // ini yang bikin peta lebih cepat muncul
          panBuffer: 0,

          // Simpan tile yang sudah dimuat agar tidak re-fetch saat pan kembali
          keepBuffer: 2,

          // Fade ringan agar tidak terasa "pop"
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

  // ── Map Skeleton ─────────────────────────────────────────────
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

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
              color: _P.b600.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.85, -0.75),
                      radius: 1.1,
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Update otomatis setiap 10 detik',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.white.withOpacity(0.60),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Zoom Controls ────────────────────────────────────────────
  Widget _buildZoomControls() {
    return Column(
      children: [
        _mapBtn(Icons.add_rounded, _zoomIn),
        const SizedBox(height: 8),
        _mapBtn(Icons.remove_rounded, _zoomOut),
        const SizedBox(height: 8),
        _mapBtn(
          Icons.my_location_rounded,
          () => _mapController.move(const LatLng(3.5952, 98.6722), 13),
        ),
      ],
    );
  }

  Widget _mapBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
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
        child: Icon(icon, color: _P.b600, size: 20),
      ),
    );
  }

  // ── Draggable Panel ──────────────────────────────────────────
  Widget _buildDraggableAngkotList() {
    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.10,
      maxChildSize: 0.70,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _P.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_P.b500, _P.b700],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Armada Aktif',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _P.ink,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _P.b50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _P.b200, width: 1),
                      ),
                      child: Text(
                        '${_angkotList.length} Unit',
                        style: const TextStyle(
                          fontSize: 12,
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
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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

  // ── Angkot Card ──────────────────────────────────────────────
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
                      _statusBadge(angkot['crowd_status']),
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
                          color: _P.ink3,
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

  Widget _statusBadge(String status) {
    final isFull = status == 'Penuh';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isFull ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFull ? const Color(0xFFFECACA) : const Color(0xFF86EFAC),
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
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
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _P.b100, width: 1.5),
            ),
            child: const Icon(
              Icons.directions_bus_outlined,
              size: 34,
              color: _P.b300,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tidak ada armada aktif',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _P.ink3,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Tidak ada angkot yang beroperasi saat ini',
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
