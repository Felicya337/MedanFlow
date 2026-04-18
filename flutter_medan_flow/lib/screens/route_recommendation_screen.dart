import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
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
  static const bg = Color(0xFFEEF4FF);
  static const card = Colors.white;
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF334155);
  static const ink3 = Color(0xFF64748B);
  static const ink4 = Color(0xFF94A3B8);
  static const dark = Color(0xFF0F2878);
}

// ─────────────────────────────────────────────
// Model: Suggestion dari Nominatim
// ─────────────────────────────────────────────
class _PlaceSuggestion {
  final String displayName;
  final String shortName;
  final double lat;
  final double lon;

  const _PlaceSuggestion({
    required this.displayName,
    required this.shortName,
    required this.lat,
    required this.lon,
  });

  factory _PlaceSuggestion.fromJson(Map<String, dynamic> j) {
    final display = j['display_name'] as String;
    final parts = display.split(',');
    final short = parts.length >= 2
        ? '${parts[0].trim()}, ${parts[1].trim()}'
        : parts[0].trim();
    return _PlaceSuggestion(
      displayName: display,
      shortName: short,
      lat: double.parse(j['lat'] as String),
      lon: double.parse(j['lon'] as String),
    );
  }
}

// ─────────────────────────────────────────────
// Nominatim Search Service
// ─────────────────────────────────────────────
class _NominatimService {
  static Future<List<_PlaceSuggestion>> search(String query) async {
    if (query.trim().length < 3) return [];
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent('$query, Medan, Sumatera Utara')}'
        '&format=json&limit=5&countrycodes=id'
        '&viewbox=98.5,3.4,98.9,3.8&bounded=0',
      );
      final res = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'MedanFlow/1.0 (medanflow@app.com)',
              'Accept-Language': 'id',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data
            .map((e) => _PlaceSuggestion.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Nominatim error: $e');
    }
    return [];
  }
}

// ══════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class RouteRecommendationScreen extends StatefulWidget {
  const RouteRecommendationScreen({super.key});

  @override
  State<RouteRecommendationScreen> createState() =>
      _RouteRecommendationScreenState();
}

class _RouteRecommendationScreenState extends State<RouteRecommendationScreen> {
  // ── Map ───────────────────────────────────────────────────────
  // FIX: Inisialisasi sekali di sini, JANGAN di dalam build()
  final MapController _mapController = MapController();
  bool _mapReady = false;

  static const LatLng _defaultCenter = LatLng(3.5952, 98.6722);

  // ── Lokasi pengguna ───────────────────────────────────────────
  LatLng?
  _userLatLng; // FIX: pakai LatLng, bukan Position (hindari isu constructor)

  // ── Origin ────────────────────────────────────────────────────
  _PlaceSuggestion? _originPlace;
  bool _originIsCurrentLocation = false;

  // ── Destination ───────────────────────────────────────────────
  _PlaceSuggestion? _destPlace;

  // ── Search state ──────────────────────────────────────────────
  List<_PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  bool _isSearchingOrigin = true;
  Timer? _debounce;

  // ── Route state ───────────────────────────────────────────────
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = false;
  List<LatLng> _polyline = [];
  int? _selectedRouteIdx;

  // ── Text Controllers ──────────────────────────────────────────
  final FocusNode _originFocus = FocusNode();
  final FocusNode _destFocus = FocusNode();
  final TextEditingController _originCtrl = TextEditingController();
  final TextEditingController _destCtrl = TextEditingController();

  // ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _detectCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController.dispose();
    _originFocus.dispose();
    _destFocus.dispose();
    _originCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  // ── GPS ───────────────────────────────────────────────────────
  Future<void> _detectCurrentLocation() async {
    if (!mounted) return;
    setState(() {
      _originIsCurrentLocation = true;
      _originCtrl.text = 'Mendeteksi lokasi...';
    });

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 12));

        if (!mounted) return;
        final latLng = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _userLatLng = latLng;
          _originIsCurrentLocation = true;
          _originCtrl.text = 'Lokasi Saya Saat Ini';
        });
        _safeMove(latLng, 14);
      } else {
        _fallbackMedan();
      }
    } catch (e) {
      debugPrint('GPS error: $e');
      _fallbackMedan();
    }
  }

  void _fallbackMedan() {
    if (!mounted) return;
    setState(() {
      _userLatLng = _defaultCenter;
      _originIsCurrentLocation = true;
      _originCtrl.text = 'Medan, Sumatera Utara';
    });
  }

  // ── Safe map move ─────────────────────────────────────────────
  void _safeMove(LatLng center, double zoom) {
    if (_mapReady) {
      _mapController.move(center, zoom);
    }
    // Kalau peta belum siap, pindah akan dilakukan di onMapReady callback
  }

  // ── Search ────────────────────────────────────────────────────
  void _onSearchChanged(String query, bool isOrigin) {
    _debounce?.cancel();

    // Kalau field origin diketik ulang → bukan lagi current location
    if (isOrigin && _originIsCurrentLocation) {
      setState(() => _originIsCurrentLocation = false);
    }

    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSuggestions = true;
      _isSearchingOrigin = isOrigin;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await _NominatimService.search(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    });
  }

  void _selectSuggestion(_PlaceSuggestion place) {
    setState(() {
      if (_isSearchingOrigin) {
        _originPlace = place;
        _originIsCurrentLocation = false;
        _originCtrl.text = place.shortName;
      } else {
        _destPlace = place;
        _destCtrl.text = place.shortName;
      }
      _suggestions = [];
      _showSuggestions = false;
    });
    _originFocus.unfocus();
    _destFocus.unfocus();
    _safeMove(LatLng(place.lat, place.lon), 14);
  }

  void _resetOriginToCurrentLocation() {
    setState(() {
      _originPlace = null;
      _originIsCurrentLocation = true;
      _originCtrl.text = _userLatLng == _defaultCenter
          ? 'Medan, Sumatera Utara'
          : 'Lokasi Saya Saat Ini';
      _suggestions = [];
      _showSuggestions = false;
    });
    if (_userLatLng != null) _safeMove(_userLatLng!, 14);
  }

  void _swapOriginDest() {
    setState(() {
      // Simpan origin sementara
      final tmpPlace = _originPlace;
      final tmpText = _originCtrl.text;
      final tmpIsGps = _originIsCurrentLocation;

      // origin ← dest
      if (_destPlace != null) {
        _originPlace = _destPlace;
        _originIsCurrentLocation = false;
        _originCtrl.text = _destCtrl.text;
      } else {
        _originPlace = null;
        _originIsCurrentLocation = false;
        _originCtrl.clear();
      }

      // dest ← origin
      if (!tmpIsGps && tmpPlace != null) {
        _destPlace = tmpPlace;
        _destCtrl.text = tmpText;
      } else {
        _destPlace = null;
        _destCtrl.clear();
      }

      _suggestions = [];
      _showSuggestions = false;
    });
  }

  // ── Fetch Routes ──────────────────────────────────────────────
  Future<void> _fetchSmartRoutes() async {
    // Tentukan koordinat origin
    LatLng? originLatLng;
    if (_originIsCurrentLocation && _userLatLng != null) {
      originLatLng = _userLatLng;
    } else if (_originPlace != null) {
      originLatLng = LatLng(_originPlace!.lat, _originPlace!.lon);
    }

    if (originLatLng == null || _destPlace == null) {
      _showSnack('Pilih lokasi asal & tujuan terlebih dahulu');
      return;
    }

    _originFocus.unfocus();
    _destFocus.unfocus();
    setState(() {
      _isLoading = true;
      _polyline = [];
      _selectedRouteIdx = null;
      _suggestions = [];
      _showSuggestions = false;
      _recommendations = [];
    });

    try {
      final apiService = ApiService();
      final url =
          '${apiService.baseUrl}/recommendations'
          '?lat=${originLatLng.latitude}&lng=${originLatLng.longitude}'
          '&dest_lat=${_destPlace!.lat}&dest_lng=${_destPlace!.lon}';

      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final List raw = jsonDecode(res.body);
        final data = raw.cast<Map<String, dynamic>>();
        setState(() {
          _recommendations = data;
          _selectedRouteIdx = data.isNotEmpty ? 0 : null;
        });
        if (data.isNotEmpty && data[0]['geometry'] != null) {
          _drawRoute(data[0]['geometry'], index: 0);
        }
      } else {
        _showSnack('Server error: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch routes error: $e');
      _showSnack('Gagal mengambil rute. Periksa koneksi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _drawRoute(dynamic geometry, {int? index}) {
    if (geometry == null || geometry is! List || geometry.isEmpty) return;
    final points = <LatLng>[
      for (final c in geometry)
        LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
    ];
    setState(() {
      _polyline = points;
      if (index != null) _selectedRouteIdx = index;
    });
    if (points.isNotEmpty) {
      _safeMove(points[points.length ~/ 2], 13.0);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: GestureDetector(
        onTap: () {
          if (_showSuggestions) setState(() => _showSuggestions = false);
          _originFocus.unfocus();
          _destFocus.unfocus();
        },
        child: Stack(
          children: [
            _buildMap(),
            // Search panel
            Positioned(
              top: MediaQuery.of(context).padding.top + 66,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchCard(),
                  if (_showSuggestions) _buildSuggestionsDropdown(),
                ],
              ),
            ),
            // Zoom + GPS controls
            Positioned(
              right: 14,
              top: MediaQuery.of(context).size.height * 0.44,
              child: _buildZoomControls(),
            ),
            // Results sheet
            _buildDraggableResults(),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            color: _P.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _P.b100, width: 1.5),
            boxShadow: [
              BoxShadow(color: _P.b500.withOpacity(0.10), blurRadius: 8),
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
      title: const Text(
        'Navigasi Pintar',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: _P.ink,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
    );
  }

  // ── Map ───────────────────────────────────────────────────────
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController, // FIX: pakai field, bukan ??=
      options: MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: 14,
        onMapReady: () {
          // FIX: set flag dan langsung pindah ke GPS jika sudah tersedia
          setState(() => _mapReady = true);
          if (_userLatLng != null) {
            _mapController.move(_userLatLng!, 14);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://api.mapbox.com/styles/v1/${ApiService.mapboxTrafficStyle}'
              '/tiles/256/{z}/{x}/{y}?access_token=${ApiService.mapboxToken}',
          userAgentPackageName: 'com.medanflow.app',
          maxNativeZoom: 18,
          keepBuffer: 4,
        ),
        if (_polyline.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _polyline,
                color: _P.b500,
                strokeWidth: 5.5,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
            ],
          ),
        MarkerLayer(markers: _buildMarkers()),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Marker asal
    LatLng? originLatLng;
    if (_originIsCurrentLocation && _userLatLng != null) {
      originLatLng = _userLatLng;
    } else if (_originPlace != null) {
      originLatLng = LatLng(_originPlace!.lat, _originPlace!.lon);
    }

    if (originLatLng != null) {
      markers.add(
        Marker(
          point: originLatLng,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _P.b600,
              boxShadow: [
                BoxShadow(color: _P.b600.withOpacity(0.4), blurRadius: 12),
              ],
            ),
            child: const Icon(
              Icons.my_location_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      );
    }

    // Marker tujuan
    if (_destPlace != null) {
      markers.add(
        Marker(
          point: LatLng(_destPlace!.lat, _destPlace!.lon),
          width: 44,
          height: 52,
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Container(width: 3, height: 12, color: Colors.redAccent),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  // ── Search Card ───────────────────────────────────────────────
  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _P.b500.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Origin field
          _buildLocationField(
            isOrigin: true,
            icon: Icons.radio_button_checked_rounded,
            iconColor: _P.b600,
            hint: 'Lokasi asal...',
            controller: _originCtrl,
            focusNode: _originFocus,
            isCurrentLocation: _originIsCurrentLocation,
            onChanged: (v) => _onSearchChanged(v, true),
            onTap: () {
              if (_originIsCurrentLocation) {
                // Izinkan ketik ulang
                setState(() {
                  _originIsCurrentLocation = false;
                  _originCtrl.clear();
                });
              }
              setState(() {
                _isSearchingOrigin = true;
                _showSuggestions = false;
              });
            },
          ),

          // Divider + swap
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Container(
                  width: 2,
                  height: 20,
                  color: _P.b100,
                  margin: const EdgeInsets.only(left: 9),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _swapOriginDest,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _P.b50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _P.b100, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.swap_vert_rounded,
                      color: _P.b600,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Destination field
          _buildLocationField(
            isOrigin: false,
            icon: Icons.location_on_rounded,
            iconColor: Colors.redAccent,
            hint: 'Cari tujuan...',
            controller: _destCtrl,
            focusNode: _destFocus,
            isCurrentLocation: false,
            onChanged: (v) => _onSearchChanged(v, false),
            onTap: () {
              setState(() {
                _isSearchingOrigin = false;
                _showSuggestions = false;
              });
            },
          ),

          const SizedBox(height: 12),

          // Search button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _fetchSmartRoutes,
              style: ElevatedButton.styleFrom(
                backgroundColor: _P.b600,
                disabledBackgroundColor: _P.b300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.alt_route_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'CARI JALUR TERCEPAT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                            letterSpacing: 0.5,
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

  Widget _buildLocationField({
    required bool isOrigin,
    required IconData icon,
    required Color iconColor,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isCurrentLocation,
    required ValueChanged<String> onChanged,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _P.ink,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _P.ink4,
              ),
            ),
            onTap: onTap,
            onChanged: onChanged,
          ),
        ),
        // Tombol kanan: GPS indicator atau clear
        if (isCurrentLocation)
          GestureDetector(
            onTap: _detectCurrentLocation,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _P.b50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.gps_fixed_rounded,
                size: 14,
                color: _P.b600,
              ),
            ),
          )
        else if (controller.text.isNotEmpty) ...[
          GestureDetector(
            onTap: () {
              controller.clear();
              setState(() {
                if (isOrigin) {
                  _originPlace = null;
                } else {
                  _destPlace = null;
                }
                _suggestions = [];
                _showSuggestions = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded, size: 14, color: _P.ink3),
            ),
          ),
          // Tombol kembali ke GPS (hanya origin)
          if (isOrigin) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _resetOriginToCurrentLocation,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _P.b50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _P.b100),
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  size: 14,
                  color: _P.b600,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  // ── Suggestions Dropdown ──────────────────────────────────────
  Widget _buildSuggestionsDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _P.b100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _P.b500.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: _isSearching
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _P.b500,
                    ),
                  ),
                ),
              )
            : _suggestions.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.search_off_rounded, color: _P.ink4, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Lokasi tidak ditemukan',
                      style: TextStyle(
                        color: _P.ink3,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < _suggestions.length; i++) ...[
                    _buildSuggestionItem(_suggestions[i], i),
                    if (i < _suggestions.length - 1)
                      Divider(height: 1, color: _P.b50, indent: 52),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildSuggestionItem(_PlaceSuggestion place, int index) {
    return InkWell(
      onTap: () => _selectSuggestion(place),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _isSearchingOrigin ? _P.b50 : Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                index == 0 ? Icons.location_on_rounded : Icons.place_outlined,
                size: 17,
                color: _isSearchingOrigin ? _P.b600 : Colors.redAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.shortName,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _P.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.displayName,
                    style: const TextStyle(fontSize: 11, color: _P.ink4),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.north_west_rounded, size: 14, color: _P.ink4),
          ],
        ),
      ),
    );
  }

  // ── Zoom Controls ─────────────────────────────────────────────
  Widget _buildZoomControls() {
    return Column(
      children: [
        _mapBtn(Icons.add_rounded, () {
          if (_mapReady)
            _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom + 1,
            );
        }),
        const SizedBox(height: 8),
        _mapBtn(Icons.remove_rounded, () {
          if (_mapReady)
            _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1,
            );
        }),
        const SizedBox(height: 8),
        _mapBtn(
          Icons.my_location_rounded,
          _detectCurrentLocation,
          accent: true,
        ),
      ],
    );
  }

  Widget _mapBtn(IconData icon, VoidCallback onTap, {bool accent = false}) {
    return Container(
      decoration: BoxDecoration(
        color: accent ? _P.b600 : _P.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: IconButton(
        icon: Icon(icon, color: accent ? Colors.white : _P.b600),
        onPressed: onTap,
        iconSize: 20,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  // ── Draggable Results Sheet ───────────────────────────────────
  Widget _buildDraggableResults() {
    return DraggableScrollableSheet(
      initialChildSize: 0.13,
      minChildSize: 0.13,
      maxChildSize: 0.72,
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
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
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
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: const BoxDecoration(
                                  color: _P.b50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.alt_route_rounded,
                                  color: _P.b300,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Masukkan tujuan & cari rute',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _P.ink3,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Ketuk kolom pencarian di atas',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: _P.ink4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        itemCount: _recommendations.length,
                        itemBuilder: (_, i) =>
                            _buildRouteCard(_recommendations[i], i),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> item, int index) {
    final isSelected = _selectedRouteIdx == index;
    return GestureDetector(
      onTap: () => _drawRoute(item['geometry'], index: index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _P.b50 : _P.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _P.b400 : _P.b100, width: 1.5),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [_P.b500, _P.b700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(colors: [_P.b50, _P.b100]),
                borderRadius: BorderRadius.circular(14),
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
                    item['eta']?.toString().split(' ').first ?? '0',
                    style: TextStyle(
                      fontSize: 22,
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name']?.toString() ?? 'Rute Medan',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: _P.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['distance']?.toString() ?? '-',
                    style: const TextStyle(fontSize: 12, color: _P.ink3),
                  ),
                  if (item['via'] != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'via ${item['via']}',
                      style: const TextStyle(fontSize: 11, color: _P.ink4),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
