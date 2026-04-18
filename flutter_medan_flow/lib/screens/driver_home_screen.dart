import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/tracking_provider.dart';
import '../services/api_service.dart';
import 'landing_page.dart';

// ─────────────────────────────────────────────
// Model: Data Driver dari SharedPreferences
// ─────────────────────────────────────────────
class _DriverData {
  final String name;
  final String vehicleId;
  final String plateNumber;
  final String route;
  final String token;

  const _DriverData({
    required this.name,
    required this.vehicleId,
    required this.plateNumber,
    required this.route,
    required this.token,
  });

  /// Key-key SharedPreferences yang dipakai saat login driver
  factory _DriverData.fromPrefs(SharedPreferences prefs) {
    return _DriverData(
      name: prefs.getString('driver_name') ?? 'Driver',
      vehicleId: prefs.getString('vehicle_id') ?? '-',
      plateNumber: prefs.getString('plate_number') ?? '-',
      route: prefs.getString('driver_route') ?? '-',
      token: prefs.getString('auth_token') ?? '',
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  DRIVER HOME SCREEN
// ══════════════════════════════════════════════════════════════
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  // ── Warna ────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF1A237E);
  static const Color _accent = Color(0xFF3949AB);
  static const Color _scaffoldBg = Color(0xFFF8F9FA);

  // ── State ────────────────────────────────────────────────────
  _DriverData? _driverData;
  Map<String, dynamic>? _insights;
  bool _loadingInsight = true;
  bool _loadingDriver = true;
  String _errorMessage = '';

  // ── GPS Tracking ─────────────────────────────────────────────
  Timer? _locationTimer;
  Position? _lastPosition;
  bool _isSendingLocation = false;

  // Interval kirim lokasi ke server (detik)
  static const int _locationIntervalSec = 5;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
    _fetchInsights();
  }

  @override
  void dispose() {
    _stopLocationTracking();
    super.dispose();
  }

  // ── Load data driver dari SharedPreferences ──────────────────
  Future<void> _loadDriverData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _driverData = _DriverData.fromPrefs(prefs);
      _loadingDriver = false;
    });
  }

  // ── Fetch insights dari API ───────────────────────────────────
  Future<void> _fetchInsights() async {
    setState(() {
      _loadingInsight = true;
      _errorMessage = '';
    });
    try {
      final response = await http
          .get(Uri.parse('${ApiService().baseUrl}/driver/insights'))
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _insights = jsonDecode(response.body);
          _loadingInsight = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat data (Error ${response.statusCode})';
          _loadingInsight = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Tidak bisa terhubung ke server.';
        _loadingInsight = false;
      });
    }
  }

  // ════════════════════════════════════════════════════════════
  //  GPS TRACKING LOGIC
  // ════════════════════════════════════════════════════════════

  /// Minta izin GPS, lalu mulai timer kirim lokasi
  Future<void> _startLocationTracking() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      if (mounted) {
        _showSnackbar(
          'Izin GPS ditolak permanen. Aktifkan di Pengaturan.',
          isError: true,
        );
      }
      return;
    }
    if (perm == LocationPermission.denied) {
      if (mounted)
        _showSnackbar('Izin GPS diperlukan untuk tracking.', isError: true);
      return;
    }

    // Kirim sekali langsung, lalu tiap interval
    await _sendCurrentLocation();
    _locationTimer = Timer.periodic(
      const Duration(seconds: _locationIntervalSec),
      (_) => _sendCurrentLocation(),
    );
  }

  /// Hentikan timer & beri tahu server bahwa driver offline
  Future<void> _stopLocationTracking() async {
    _locationTimer?.cancel();
    _locationTimer = null;

    // Beritahu server driver offline
    try {
      if (_driverData != null && _driverData!.token.isNotEmpty) {
        await http
            .post(
              Uri.parse('${ApiService().baseUrl}/driver/offline'),
              headers: _authHeaders(),
            )
            .timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint('Offline notify error: $e');
    }
  }

  /// Ambil GPS saat ini & kirim ke /driver/location
  Future<void> _sendCurrentLocation() async {
    if (_isSendingLocation) return; // Hindari request tumpang tindih
    _isSendingLocation = true;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;
      setState(() => _lastPosition = position);

      if (_driverData == null) return;

      final body = jsonEncode({
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed, // m/s
        'heading': position.heading,
        'accuracy': position.accuracy,
        'vehicle_id': _driverData!.vehicleId,
        'timestamp': position.timestamp.toIso8601String(),
      });

      final response = await http
          .post(
            Uri.parse('${ApiService().baseUrl}/driver/location'),
            headers: {..._authHeaders(), 'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('Location send failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Send location error: $e');
    } finally {
      _isSendingLocation = false;
    }
  }

  Map<String, String> _authHeaders() => {
    if (_driverData != null && _driverData!.token.isNotEmpty)
      'Authorization': 'Bearer ${_driverData!.token}',
  };

  // ── Toggle tracking (dipanggil dari tombol) ───────────────────
  Future<void> _handleTrackingToggle(TrackingProvider tracking) async {
    if (tracking.isTracking) {
      // Hentikan
      await _stopLocationTracking();
      tracking.toggleTracking();
      if (mounted) _showSnackbar('Tracking dihentikan. Anda offline.');
    } else {
      // Mulai
      tracking.toggleTracking();
      await _startLocationTracking();
      if (mounted)
        _showSnackbar('Tracking aktif! Posisi Anda dikirim ke server.');
    }
  }

  // ── Logout ────────────────────────────────────────────────────
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Driver?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Pastikan tracking dihentikan sebelum logout
              final tracking = context.read<TrackingProvider>();
              if (tracking.isTracking) {
                await _stopLocationTracking();
                tracking.toggleTracking();
              }
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LandingPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'YA, KELUAR',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: _primary,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: const Text(
                'MEDAN FLOW — DRIVER',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primary, _accent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _fetchInsights,
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: _showLogoutConfirmation,
              ),
              const SizedBox(width: 10),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status Header ─────────────────────────────
                Stack(
                  children: [
                    Container(
                      height: 120,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_accent, _scaffoldBg],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    _buildStatusHeader(),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── GPS Status chip ───────────────────
                      _buildGpsStatusChip(),
                      const SizedBox(height: 20),

                      // ── Mini Map ──────────────────────────
                      const Text(
                        'Live Monitor Trafik Medan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildTrafficMiniMap(),
                      const SizedBox(height: 30),

                      // ── Insights ──────────────────────────
                      const Text(
                        'Kondisi Operasional',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (_loadingInsight)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_errorMessage.isNotEmpty)
                        _buildErrorSection()
                      else
                        _buildInsightSection(),

                      const SizedBox(height: 30),

                      // ── Tracking Button ───────────────────
                      _buildTrackingButton(),
                      const SizedBox(height: 25),

                      // ── Vehicle Info ──────────────────────
                      _buildVehicleInfo(),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── GPS Status Chip ──────────────────────────────────────────
  Widget _buildGpsStatusChip() {
    if (_lastPosition == null) return const SizedBox.shrink();
    final lat = _lastPosition!.latitude.toStringAsFixed(5);
    final lng = _lastPosition!.longitude.toStringAsFixed(5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'GPS aktif • $lat, $lng',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Header ─────────────────────────────────────────────
  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Consumer<TrackingProvider>(
        builder: (ctx, tracking, _) {
          final name = _loadingDriver ? '...' : (_driverData?.name ?? 'Driver');
          return Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: _primary.withOpacity(0.1),
                child: const Icon(
                  Icons.person_rounded,
                  color: _primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: tracking.isTracking
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tracking.isTracking
                              ? 'SEDANG BERTUGAS'
                              : 'SEDANG ISTIRAHAT',
                          style: TextStyle(
                            color: tracking.isTracking
                                ? Colors.green
                                : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Mini Map ─────────────────────────────────────────────────
  Widget _buildTrafficMiniMap() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                // Kalau ada posisi GPS, pusatkan di sana
                initialCenter: _lastPosition != null
                    ? LatLng(_lastPosition!.latitude, _lastPosition!.longitude)
                    : const LatLng(3.5952, 98.6722),
                initialZoom: 13,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/256/{z}/{x}/{y}@2x?access_token=${ApiService.mapboxToken}',
                  userAgentPackageName: 'com.medanflow.app',
                ),
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/mapbox/traffic-night-v2/tiles/256/{z}/{x}/{y}@2x?access_token=${ApiService.mapboxToken}',
                  userAgentPackageName: 'com.medanflow.app',
                  backgroundColor: Colors.transparent,
                ),
                // Marker posisi driver saat ini
                if (_lastPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          _lastPosition!.latitude,
                          _lastPosition!.longitude,
                        ),
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _accent.withOpacity(0.5),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            // Label overlay
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _lastPosition != null
                            ? Colors.greenAccent
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _lastPosition != null ? 'Live' : 'Offline',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error Section ─────────────────────────────────────────────
  Widget _buildErrorSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
          TextButton(onPressed: _fetchInsights, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  // ── Insights Section ──────────────────────────────────────────
  Widget _buildInsightSection() {
    if (_insights == null) return const SizedBox.shrink();

    final condition = (_insights!['weather']?['condition'] ?? '')
        .toString()
        .toLowerCase();
    final isRain = condition.contains('hujan');

    return Column(
      children: [
        Row(
          children: [
            _insightTile(
              'Cuaca Medan',
              _insights!['weather']?['temp'] ?? '--',
              _insights!['weather']?['condition'] ?? '-',
              isRain ? Icons.cloudy_snowing : Icons.wb_sunny_outlined,
              isRain ? Colors.blue : Colors.orange,
            ),
            const SizedBox(width: 15),
            _insightTile(
              'Trafik',
              _insights!['traffic']?['description'] ?? '--',
              'Skor Kerja: ${_insights!['work_score'] ?? 0}',
              Icons.traffic_outlined,
              Colors.deepOrange,
            ),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: (_insights!['is_good_to_work'] ?? false)
                ? Colors.green.shade50
                : Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (_insights!['is_good_to_work'] ?? false)
                  ? Colors.green.shade200
                  : Colors.red.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                (_insights!['is_good_to_work'] ?? false)
                    ? Icons.check_circle_rounded
                    : Icons.info_rounded,
                color: (_insights!['is_good_to_work'] ?? false)
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _insights!['recommendation'] ?? '-',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _insightTile(
    String label,
    String value,
    String sub,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              sub,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Tracking Button ───────────────────────────────────────────
  Widget _buildTrackingButton() {
    return Consumer<TrackingProvider>(
      builder: (ctx, tracking, _) {
        final active = tracking.isTracking;
        return GestureDetector(
          onTap: () => _handleTrackingToggle(tracking),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: active
                    ? [Colors.red.shade600, Colors.red.shade800]
                    : [_primary, _accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: (active ? Colors.red : _primary).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  active
                      ? Icons.stop_circle_rounded
                      : Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 55,
                ),
                const SizedBox(height: 10),
                Text(
                  active ? 'BERHENTI MENARIK' : 'MULAI MENARIK!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  active
                      ? 'Posisi Anda sedang dipantau penumpang (${_locationIntervalSec}s)'
                      : 'Ketuk untuk online di peta Medan',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Vehicle Info ─────────────────────────────────────────────
  Widget _buildVehicleInfo() {
    if (_loadingDriver) {
      return const Center(child: CircularProgressIndicator());
    }
    final vehicle = _driverData?.vehicleId ?? '-';
    final plate = _driverData?.plateNumber ?? '-';
    final route = _driverData?.route ?? '-';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: _primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$vehicle ($plate)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Trayek: $route',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_user_rounded, color: Colors.blue, size: 20),
        ],
      ),
    );
  }
}
