import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
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

// ─────────────────────────────────────────────
// Model untuk hasil pencarian Nominatim
// ─────────────────────────────────────────────
class _PlaceSuggestion {
  final String displayName;
  final double lat;
  final double lon;

  const _PlaceSuggestion({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  factory _PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return _PlaceSuggestion(
      displayName: json['display_name'] as String,
      lat: double.parse(json['lat'] as String),
      lon: double.parse(json['lon'] as String),
    );
  }

  /// Nama singkat: hanya bagian pertama sebelum koma
  String get shortName => displayName.split(',').first.trim();
}

class TravelTimePredictionScreen extends StatefulWidget {
  const TravelTimePredictionScreen({super.key});

  @override
  State<TravelTimePredictionScreen> createState() =>
      _TravelTimePredictionScreenState();
}

class _TravelTimePredictionScreenState
    extends State<TravelTimePredictionScreen> {
  // ── Controllers ───────────────────────────────────────
  final MapController _mapController = MapController();
  final TextEditingController _originTextCtrl = TextEditingController();
  final TextEditingController _destTextCtrl = TextEditingController();
  final FocusNode _originFocus = FocusNode();
  final FocusNode _destFocus = FocusNode();

  // ── Constants ─────────────────────────────────────────
  static const _medanCenter = LatLng(3.5952, 98.6722);

  // ── State ─────────────────────────────────────────────
  /// 0 = pilih asal, 1 = pilih tujuan, 2 = tampilkan hasil
  int _step = 0;
  bool _isLoading = false;
  bool _isLocating = false; // sedang ambil GPS

  LatLng? _originPoint;
  LatLng? _destPoint;
  String _originLabel = '';
  String _destLabel = '';
  Map<String, dynamic>? _predictionData;
  List<LatLng> _routePoints = [];

  LatLng _currentMapCenter = _medanCenter;

  // ── Autocomplete ──────────────────────────────────────
  List<_PlaceSuggestion> _originSuggestions = [];
  List<_PlaceSuggestion> _destSuggestions = [];
  bool _showOriginSuggestions = false;
  bool _showDestSuggestions = false;
  Timer? _debounce;

  // ── Lifecycle ─────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // Auto-detect lokasi saat pertama buka
    _autoDetectLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _originTextCtrl.dispose();
    _destTextCtrl.dispose();
    _originFocus.dispose();
    _destFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── GPS / Location ────────────────────────────────────
  Future<void> _autoDetectLocation() async {
    setState(() => _isLocating = true);
    try {
      // Cek & minta permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          _showSnackBar('Izin lokasi ditolak. Pilih lokasi manual di peta.');
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final latLng = LatLng(pos.latitude, pos.longitude);

      // Reverse geocode untuk nama lokasi
      final label = await _reverseGeocode(latLng);

      if (mounted) {
        setState(() {
          _originPoint = latLng;
          _originLabel = label;
          _originTextCtrl.text = label;
          _currentMapCenter = latLng;
          // Langsung ke step 1 (pilih tujuan)
          _step = 1;
        });
        _mapController.move(latLng, 15.0);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Tidak bisa ambil lokasi GPS. Pilih manual di peta.');
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// Mengambil lokasi GPS ulang (tombol my-location)
  Future<void> _relocateOrigin() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _showSnackBar('Izin lokasi ditolak.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      final label = await _reverseGeocode(latLng);

      if (mounted) {
        setState(() {
          _originPoint = latLng;
          _originLabel = label;
          _originTextCtrl.text = label;
          _step = 1;
        });
        _mapController.move(latLng, 15.0);
      }
    } catch (_) {
      _showSnackBar('Gagal mendapatkan lokasi.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // ── Geocoding ─────────────────────────────────────────
  Future<String> _reverseGeocode(LatLng point) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${point.latitude}&lon=${point.longitude}'
        '&format=json&addressdetails=1',
      );
      final res = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'MedanFlowApp/1.0',
              'Accept-Language': 'id',
            },
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>?;
        return (addr?['road'] as String?) ??
            (addr?['suburb'] as String?) ??
            (data['display_name'] as String? ?? 'Lokasi dipilih');
      }
    } catch (_) {}
    return 'Lokasi dipilih';
  }

  Future<List<_PlaceSuggestion>> _searchPlaces(String query) async {
    if (query.length < 3) return [];
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=5'
        '&viewbox=98.4,3.3,98.9,3.8&bounded=0', // bias ke area Medan
      );
      final res = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'MedanFlowApp/1.0',
              'Accept-Language': 'id',
            },
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((e) => _PlaceSuggestion.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  void _onOriginTextChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await _searchPlaces(val);
      if (mounted) {
        setState(() {
          _originSuggestions = results;
          _showOriginSuggestions = results.isNotEmpty;
        });
      }
    });
  }

  void _onDestTextChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await _searchPlaces(val);
      if (mounted) {
        setState(() {
          _destSuggestions = results;
          _showDestSuggestions = results.isNotEmpty;
        });
      }
    });
  }

  void _selectOriginSuggestion(_PlaceSuggestion s) {
    final latLng = LatLng(s.lat, s.lon);
    setState(() {
      _originPoint = latLng;
      _originLabel = s.shortName;
      _originTextCtrl.text = s.shortName;
      _showOriginSuggestions = false;
      _step = 1;
    });
    _mapController.move(latLng, 15.0);
    _originFocus.unfocus();
  }

  void _selectDestSuggestion(_PlaceSuggestion s) {
    final latLng = LatLng(s.lat, s.lon);
    setState(() {
      _destPoint = latLng;
      _destLabel = s.shortName;
      _destTextCtrl.text = s.shortName;
      _showDestSuggestions = false;
    });
    _mapController.move(latLng, 15.0);
    _destFocus.unfocus();
    // Langsung hitung kalau asal sudah ada
    if (_originPoint != null) _calculateRoute();
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
      _showSnackBar('Gagal menganalisis rute. Cek koneksi ke server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Konfirmasi pin tengah peta (mode manual)
  void _confirmMapPin() async {
    if (_step == 0) {
      final label = await _reverseGeocode(_currentMapCenter);
      setState(() {
        _originPoint = _currentMapCenter;
        _originLabel = label;
        _originTextCtrl.text = label;
        _step = 1;
      });
    } else if (_step == 1) {
      final label = await _reverseGeocode(_currentMapCenter);
      setState(() {
        _destPoint = _currentMapCenter;
        _destLabel = label;
        _destTextCtrl.text = label;
      });
      _calculateRoute();
    }
  }

  void _resetScreen() {
    setState(() {
      _step = 0;
      _originPoint = null;
      _destPoint = null;
      _originLabel = '';
      _destLabel = '';
      _originTextCtrl.clear();
      _destTextCtrl.clear();
      _predictionData = null;
      _routePoints = [];
      _showOriginSuggestions = false;
      _showDestSuggestions = false;
    });
    _mapController.move(_medanCenter, 15.0);
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          // Pin tengah peta hanya saat mode manual (belum ada titik yang di-set via teks)
          if (_step < 2 && _shouldShowPin()) _buildCenterPin(),
          // Search panel (selalu tampil saat step < 2)
          if (_step < 2) _buildSearchPanel(),
          // Tombol konfirmasi pin (hanya saat manual)
          if (_step < 2 && _shouldShowPin()) _buildConfirmPinButton(),
          // Hasil
          if (_step == 2 && _predictionData != null) _buildResultSheet(),
          // Overlay loading
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  /// Pin tengah ditampilkan jika:
  /// - step 0: asal belum ditetapkan via teks
  /// - step 1: tujuan belum ditetapkan via teks
  bool _shouldShowPin() {
    if (_step == 0) return _originPoint == null;
    if (_step == 1) return _destPoint == null;
    return false;
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
      title: _step == 2
          ? ShaderMask(
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
            )
          : null,
    );
  }

  // ── Map ───────────────────────────────────────────────
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _medanCenter,
        initialZoom: 15.0,
        onPositionChanged: (position, hasGesture) {
          if (hasGesture && _step < 2 && position.center != null) {
            _currentMapCenter = position.center!;
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://api.mapbox.com/styles/v1/mapbox/streets-v12'
              '/tiles/256/{z}/{x}/{y}?access_token=${ApiService.mapboxToken}',
          userAgentPackageName: 'com.medanflow.app',
          keepBuffer: 4,
          maxNativeZoom: 18,
          minNativeZoom: 10,
          tileSize: 256,
        ),
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
        MarkerLayer(
          markers: [
            if (_originPoint != null)
              _buildMarker(
                point: _originPoint!,
                color: _P.b600,
                icon: Icons.my_location_rounded,
              ),
            if (_destPoint != null && _step >= 1)
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
            Icon(
              Icons.location_on_rounded,
              color: isOrigin ? _P.b500 : const Color(0xFFEA580C),
              size: 52,
              shadows: [
                Shadow(
                  color: (isOrigin ? _P.b600 : const Color(0xFFEA580C))
                      .withOpacity(0.40),
                  blurRadius: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Search Panel ──────────────────────────────────────
  Widget _buildSearchPanel() {
    return Positioned(
      top: 90,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card input
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _P.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _P.b100, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _P.b500.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── Asal ──────────────────────────────
                _buildSearchField(
                  controller: _originTextCtrl,
                  focusNode: _originFocus,
                  hint: 'Lokasi asal…',
                  icon: Icons.my_location_rounded,
                  iconColor: _P.b600,
                  onChanged: _onOriginTextChanged,
                  trailing: _isLocating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _P.b500,
                          ),
                        )
                      : IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          icon: const Icon(
                            Icons.gps_fixed_rounded,
                            size: 18,
                            color: _P.b500,
                          ),
                          tooltip: 'Gunakan lokasi saat ini',
                          onPressed: _relocateOrigin,
                        ),
                ),

                // Divider dengan icon panah
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Divider(color: _P.b100, thickness: 1),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _P.b50,
                          shape: BoxShape.circle,
                          border: Border.all(color: _P.b100),
                        ),
                        child: const Icon(
                          Icons.swap_vert_rounded,
                          size: 14,
                          color: _P.b600,
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: _P.b100, thickness: 1),
                      ),
                    ],
                  ),
                ),

                // ── Tujuan ────────────────────────────
                _buildSearchField(
                  controller: _destTextCtrl,
                  focusNode: _destFocus,
                  hint: 'Cari tujuan perjalanan…',
                  icon: Icons.flag_rounded,
                  iconColor: const Color(0xFFDC2626),
                  onChanged: _onDestTextChanged,
                ),
              ],
            ),
          ),

          // ── Suggestions asal ──────────────────────
          if (_showOriginSuggestions && _originSuggestions.isNotEmpty)
            _buildSuggestionList(
              suggestions: _originSuggestions,
              onSelect: _selectOriginSuggestion,
            ),

          // ── Suggestions tujuan ────────────────────
          if (_showDestSuggestions && _destSuggestions.isNotEmpty)
            _buildSuggestionList(
              suggestions: _destSuggestions,
              onSelect: _selectDestSuggestion,
            ),

          // ── Petunjuk geser peta ───────────────────
          if (_step == 1 && _destPoint == null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _P.ink.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 14,
                      color: Colors.white70,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Geser peta untuk pin manual atau ketik lokasi tujuan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required ValueChanged<String> onChanged,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: _P.ink,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: _P.ink3,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildSuggestionList({
    required List<_PlaceSuggestion> suggestions,
    required ValueChanged<_PlaceSuggestion> onSelect,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.b100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _P.b500.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: _P.b50),
          itemBuilder: (_, i) {
            final s = suggestions[i];
            return ListTile(
              dense: true,
              leading: const Icon(
                Icons.place_outlined,
                size: 18,
                color: _P.b500,
              ),
              title: Text(
                s.shortName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _P.ink,
                ),
              ),
              subtitle: Text(
                s.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: _P.ink3),
              ),
              onTap: () => onSelect(s),
            );
          },
        ),
      ),
    );
  }

  // ── Confirm Pin Button ────────────────────────────────
  Widget _buildConfirmPinButton() {
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
          onPressed: _isLoading ? null : _confirmMapPin,
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
              child: Text(
                _step == 0
                    ? 'KONFIRMASI LOKASI ASAL'
                    : 'KONFIRMASI LOKASI TUJUAN',
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

  // ── Loading Overlay ───────────────────────────────────
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.25),
      child: const Center(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: _P.b500),
                SizedBox(height: 14),
                Text(
                  'Menganalisis rute…',
                  style: TextStyle(fontWeight: FontWeight.w700, color: _P.ink),
                ),
              ],
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

            // Lokasi ringkas
            if (_originLabel.isNotEmpty || _destLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.my_location_rounded,
                      size: 13,
                      color: _P.b600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _originLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _P.ink3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: _P.ink3,
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.flag_rounded,
                      size: 13,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _destLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _P.ink3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Header gradient
            Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
