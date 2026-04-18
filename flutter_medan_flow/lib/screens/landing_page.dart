import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_medan_flow/services/api_service.dart';
import 'login_screen.dart';
import 'route_recommendation_screen.dart';
import 'travel_time_prediction_screen.dart';
import 'traffic_heatmap_screen.dart';
import 'angkot_tracking_screen.dart';
import 'notification_screen.dart';
import 'onboarding_overlay.dart';

// ─────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────
class _T {
  // Blues
  static const b50 = Color(0xFFEFF6FF);
  static const b100 = Color(0xFFDBEAFE);
  static const b200 = Color(0xFFBFDBFE);
  static const b300 = Color(0xFF93C5FD);
  static const b400 = Color(0xFF60A5FA);
  static const b500 = Color(0xFF3B82F6);
  static const b600 = Color(0xFF2563EB);
  static const b700 = Color(0xFF1D4ED8);
  static const b800 = Color(0xFF1E40AF);
  static const b900 = Color(0xFF1E3A8A);

  // Neutrals
  static const bg = Color(0xFFF0F5FF);
  static const card = Colors.white;
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF1E293B);
  static const ink3 = Color(0xFF475569);
  static const ink4 = Color(0xFF94A3B8);
  static const ink5 = Color(0xFFCBD5E1);

  // Status
  static const green = Color(0xFF16A34A);
  static const greenBg = Color(0xFFF0FDF4);
  static const red = Color(0xFFDC2626);
  static const redBg = Color(0xFFFEF2F2);
  static const orange = Color(0xFFEA580C);
  static const amber = Color(0xFFF59E0B);

  // Brand dark
  static const navy = Color(0xFF0B1D6E);
  static const dark = Color(0xFF0A1545);
}

// ─────────────────────────────────────────────
// Weather data model
// ─────────────────────────────────────────────
class _WeatherData {
  final String condition;
  final String icon; // 'sunny' | 'cloudy' | 'rainy'
  final String temp;
  final String humidity;
  final String windSpeed;
  final String location;
  final String title;
  final List<String> tips;

  const _WeatherData({
    required this.condition,
    required this.icon,
    required this.temp,
    required this.humidity,
    required this.windSpeed,
    required this.location,
    required this.title,
    required this.tips,
  });

  factory _WeatherData.fromJson(Map<String, dynamic> j) => _WeatherData(
    condition: j['condition'] as String? ?? 'Berawan',
    icon: j['icon'] as String? ?? 'cloudy',
    temp: j['temp'] as String? ?? '29°C',
    humidity: j['humidity'] as String? ?? '70%',
    windSpeed: j['wind_speed'] as String? ?? '10 m/s',
    location: j['location'] as String? ?? 'Medan, Indonesia',
    title: j['title'] as String? ?? 'Cuaca normal',
    tips: List<String>.from(j['tips'] as List? ?? []),
  );

  factory _WeatherData.fallback() => const _WeatherData(
    condition: 'Berawan',
    icon: 'cloudy',
    temp: '29°C',
    humidity: '70%',
    windSpeed: '10 m/s',
    location: 'Medan, Indonesia',
    title: 'Mendung – tetap waspada',
    tips: ['Siapkan perlengkapan hujan', 'Perhatikan kondisi jalan'],
  );
}

// ─────────────────────────────────────────────
// Nominatim place
// ─────────────────────────────────────────────
class _Place {
  final String display;
  final String short;
  final double lat;
  final double lon;
  const _Place({
    required this.display,
    required this.short,
    required this.lat,
    required this.lon,
  });
  factory _Place.fromJson(Map<String, dynamic> j) {
    final d = j['display_name'] as String;
    final parts = d.split(',');
    final s = parts.length >= 2
        ? '${parts[0].trim()}, ${parts[1].trim()}'
        : parts[0].trim();
    return _Place(
      display: d,
      short: s,
      lat: double.parse(j['lat'] as String),
      lon: double.parse(j['lon'] as String),
    );
  }
}

Future<List<_Place>> _nominatimSearch(String q) async {
  if (q.trim().length < 3) return [];
  try {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent('$q, Medan, Sumatera Utara')}'
      '&format=json&limit=5&countrycodes=id'
      '&viewbox=98.5,3.4,98.9,3.8&bounded=0',
    );
    final r = await http
        .get(
          uri,
          headers: {'User-Agent': 'MedanFlow/1.0', 'Accept-Language': 'id'},
        )
        .timeout(const Duration(seconds: 8));
    if (r.statusCode == 200) {
      return (jsonDecode(r.body) as List)
          .map((e) => _Place.fromJson(e))
          .toList();
    }
  } catch (e) {
    debugPrint('Nominatim: $e');
  }
  return [];
}

// ══════════════════════════════════════════════════════════════
//  LANDING PAGE
// ══════════════════════════════════════════════════════════════
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  // ── Map ──────────────────────────────────────────────────────
  final _mapCtrl = MapController();
  static const _medan = LatLng(3.5952, 98.6722);

  // ── GPS ──────────────────────────────────────────────────────
  LatLng? _userLatLng;

  // ── Weather ──────────────────────────────────────────────────
  _WeatherData? _weather;
  bool _weatherLoading = true;
  bool _weatherExpanded = false;

  // ── Notifications ────────────────────────────────────────────
  int _unread = 0;
  bool _showBanner = false;
  String _bannerMsg = '';

  // ── Nav ──────────────────────────────────────────────────────
  int _activeNav = 0;

  // ── Angkot live markers ───────────────────────────────────────
  List<Marker> _angkotMarkers = [];
  Timer? _angkotTimer;

  // ── Bottom sheet ─────────────────────────────────────────────
  final _sheetCtrl = DraggableScrollableController();
  static const double _sizeCollapsed =
      0.18; // sedikit lebih tinggi agar tombol driver muat
  static const double _sizeSearch = 0.48;
  static const double _sizeResults = 0.85;

  // ── Search state ─────────────────────────────────────────────
  int _sheetPhase = 0;

  _Place? _originPlace;
  _Place? _destPlace;
  bool _originIsGps = true;
  String _originLabel = 'Lokasi Saya';

  List<_Place> _suggestions = [];
  bool _searchingFor = false;
  bool _loadingSugg = false;
  Timer? _debounce;

  final _originCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _originFocus = FocusNode();
  final _destFocus = FocusNode();

  // ── Trip results ─────────────────────────────────────────────
  bool _tripLoading = false;
  Map<String, dynamic>? _tripResult;

  // ── Onboarding ────────────────────────────────────────────────
  final _keyHeader = GlobalKey();
  final _keyWeather = GlobalKey();
  final _keyStartTrip = GlobalKey();
  final _keyNavAngkot = GlobalKey();
  final _keyNavTraffic = GlobalKey();
  static const _kObDone = 'onboarding_done_v4';
  bool _obDone = false;

  // ── Pulse animation ───────────────────────────────────────────
  late AnimationController _pulseCtrl;

  // ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fetchWeather();
    _checkNotifications();
    _detectGps();
    _fetchAngkots();
    _angkotTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchAngkots(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOnboard());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _angkotTimer?.cancel();
    _sheetCtrl.dispose();
    _debounce?.cancel();
    _originCtrl.dispose();
    _destCtrl.dispose();
    _originFocus.dispose();
    _destFocus.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  DATA FETCHING
  // ─────────────────────────────────────────────────────────────

  Future<void> _fetchWeather() async {
    setState(() => _weatherLoading = true);
    try {
      final r = await http
          .get(Uri.parse('${ApiService().baseUrl}/weather/current'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200 && mounted) {
        final json = jsonDecode(r.body) as Map<String, dynamic>;
        setState(() {
          _weather = _WeatherData.fromJson(json);
          _weatherLoading = false;
        });
      } else {
        if (mounted)
          setState(() {
            _weather = _WeatherData.fallback();
            _weatherLoading = false;
          });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _weather = _WeatherData.fallback();
          _weatherLoading = false;
        });
    }
  }

  Future<void> _checkNotifications() async {
    try {
      final data = await ApiService().getNotifications();
      if (!mounted) return;
      setState(() {
        _unread = data['unread_count'] as int;
        if (_unread > 0) {
          _showBanner = true;
          _bannerMsg = data['alerts'][0]['message'] as String;
        }
      });
    } catch (_) {}
  }

  Future<void> _detectGps() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (!mounted) return;
        final ll = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _userLatLng = ll;
          _originLabel = 'Lokasi Saya Saat Ini';
        });
        _mapCtrl.move(ll, 14);
      }
    } catch (e) {
      debugPrint('GPS: $e');
    }
  }

  Future<void> _fetchAngkots() async {
    try {
      final data = await ApiService().getActiveAngkots();
      if (!mounted) return;
      final m = <Marker>[];
      for (final a in data) {
        final full = a['crowd_status'] == 'Penuh';
        final color = full ? _T.red : _T.b600;
        m.add(
          Marker(
            point: LatLng(
              double.parse(a['latitude'].toString()),
              double.parse(a['longitude'].toString()),
            ),
            width: 38,
            height: 38,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(.45),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        );
      }
      setState(() => _angkotMarkers = m);
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────
  //  SEARCH
  // ─────────────────────────────────────────────────────────────

  void _onSearchChanged(String q, bool isOrigin) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _loadingSugg = false;
      });
      return;
    }
    setState(() => _loadingSugg = true);
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      final res = await _nominatimSearch(q);
      if (mounted)
        setState(() {
          _suggestions = res;
          _loadingSugg = false;
        });
    });
  }

  void _selectPlace(_Place p, bool isOrigin) {
    setState(() {
      if (isOrigin) {
        _originPlace = p;
        _originIsGps = false;
        _originLabel = p.short;
        _originCtrl.text = p.short;
      } else {
        _destPlace = p;
        _destCtrl.text = p.short;
      }
      _suggestions = [];
      _loadingSugg = false;
    });
    _originFocus.unfocus();
    _destFocus.unfocus();
    _mapCtrl.move(LatLng(p.lat, p.lon), 14);

    final hasOrigin = _originIsGps ? _userLatLng != null : _originPlace != null;
    final hasDest = isOrigin ? _destPlace != null : true;
    if (hasOrigin && hasDest) {
      _fetchTripResults();
    } else {
      if (isOrigin) _destFocus.requestFocus();
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  TRIP
  // ─────────────────────────────────────────────────────────────

  Future<void> _fetchTripResults() async {
    final hasOrigin = _originIsGps ? _userLatLng != null : _originPlace != null;
    if (!hasOrigin || _destPlace == null) {
      _expandToSearch();
      _showSnack('Pilih lokasi asal & tujuan terlebih dahulu', isError: true);
      return;
    }

    setState(() {
      _tripLoading = true;
      _tripResult = null;
    });
    _originFocus.unfocus();
    _destFocus.unfocus();

    double oLat, oLng;
    if (_originIsGps && _userLatLng != null) {
      oLat = _userLatLng!.latitude;
      oLng = _userLatLng!.longitude;
    } else {
      oLat = _originPlace!.lat;
      oLng = _originPlace!.lon;
    }
    final dLat = _destPlace!.lat;
    final dLng = _destPlace!.lon;

    try {
      final base = ApiService().baseUrl;
      final results = await Future.wait([
        http.get(
          Uri.parse(
            '$base/recommendations?lat=$oLat&lng=$oLng&dest_lat=$dLat&dest_lng=$dLng',
          ),
        ),
        http.get(Uri.parse('$base/traffic-heatmap?minutes=5')),
        http.get(Uri.parse('$base/travel-time/predict')),
      ]).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      setState(() {
        _tripResult = {
          'routes': results[0].statusCode == 200
              ? jsonDecode(results[0].body) as List
              : <dynamic>[],
          'heatmap': results[1].statusCode == 200
              ? jsonDecode(results[1].body)
              : null,
          'estimate': results[2].statusCode == 200
              ? jsonDecode(results[2].body) as Map<String, dynamic>
              : null,
        };
        _sheetPhase = 3;
      });

      final routes = _tripResult!['routes'] as List;
      if (routes.isNotEmpty && routes[0]['geometry'] != null) {
        final geo = routes[0]['geometry'] as List;
        if (geo.isNotEmpty) {
          final mid = geo[geo.length ~/ 2];
          _mapCtrl.move(
            LatLng((mid[1] as num).toDouble(), (mid[0] as num).toDouble()),
            13,
          );
        }
      }

      _sheetCtrl.animateTo(
        _sizeResults,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } catch (e) {
      if (mounted)
        _showSnack('Gagal memuat data. Cek koneksi server.', isError: true);
    } finally {
      if (mounted) setState(() => _tripLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? _T.red : _T.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  SHEET HELPERS
  // ─────────────────────────────────────────────────────────────

  void _expandToSearch() {
    setState(() {
      _sheetPhase = 1;
      _suggestions = [];
    });
    _sheetCtrl.animateTo(
      _sizeSearch,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
    Future.delayed(const Duration(milliseconds: 380), () {
      if (mounted && _destCtrl.text.isEmpty) _destFocus.requestFocus();
    });
  }

  void _collapseSheet() {
    setState(() {
      _sheetPhase = 0;
      _suggestions = [];
      _tripResult = null;
      _destPlace = null;
      _destCtrl.clear();
      if (!_originIsGps) {
        _originPlace = null;
        _originIsGps = true;
        _originLabel = 'Lokasi Saya';
        _originCtrl.clear();
      }
    });
    _originFocus.unfocus();
    _destFocus.unfocus();
    _sheetCtrl.animateTo(
      _sizeCollapsed,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInCubic,
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  ONBOARDING
  // ─────────────────────────────────────────────────────────────

  Future<void> _maybeOnboard() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kObDone) ?? false) {
      if (mounted) setState(() => _obDone = true);
      return;
    }
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted && !_obDone) _startOnboarding();
      });
    }
  }

  void _startOnboarding() {
    OnboardingOverlay.show(
      context: context,
      steps: [
        OnboardingStep(
          targetKey: _keyHeader,
          icon: OnboardingIcon.notification,
          title: 'Selamat Datang di MedFlow!',
          description:
              'Navigasi angkot Medan berbasis AI. Tap notifikasi untuk peringatan kemacetan real-time.',
          padding: const EdgeInsets.all(8),
        ),
        OnboardingStep(
          targetKey: _keyWeather,
          icon: OnboardingIcon.weather,
          title: 'Cuaca Real-time Medan',
          description:
              'Informasi suhu, kelembapan & tips perjalanan hari ini langsung dari OpenWeather.',
          padding: const EdgeInsets.all(6),
        ),
        OnboardingStep(
          targetKey: _keyStartTrip,
          icon: OnboardingIcon.route,
          title: 'Mulai Perjalanan',
          description:
              'Tap di sini lalu pilih tujuanmu. Angkot tercepat, kondisi lalu lintas, dan estimasi waktu tampil sekaligus.',
          padding: const EdgeInsets.all(8),
        ),
        OnboardingStep(
          targetKey: _keyNavAngkot,
          icon: OnboardingIcon.angkot,
          title: 'Live Tracking Angkot',
          description:
              'Posisi & kepadatan angkot Medan terpantau langsung di peta secara real-time.',
          padding: const EdgeInsets.all(6),
        ),
        OnboardingStep(
          targetKey: _keyNavTraffic,
          icon: OnboardingIcon.traffic,
          title: 'Prediksi Kemacetan',
          description:
              'Heatmap kemacetan 30 menit ke depan untuk menentukan waktu terbaik berangkat.',
          padding: const EdgeInsets.all(6),
        ),
      ],
      onFinished: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kObDone, true);
        if (mounted) setState(() => _obDone = true);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
          _originFocus.unfocus();
          _destFocus.unfocus();
        },
        child: Stack(
          children: [
            _buildMap(),
            // Gradient overlay untuk legibility teks di atas
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 220,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _T.navy.withOpacity(0.82),
                        _T.navy.withOpacity(0.30),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Top overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    _buildWeatherCard(),
                    if (_showBanner) _buildAlertBanner(),
                  ],
                ),
              ),
            ),
            // GPS fab
            Positioned(
              right: 14,
              bottom: 200,
              child: _mapFab(Icons.my_location_rounded, _detectGps),
            ),
            // Layer fab
            Positioned(
              right: 14,
              bottom: 254,
              child: _mapFab(Icons.layers_outlined, () {}),
            ),
            _buildTripSheet(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  MAP
  // ─────────────────────────────────────────────────────────────

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapCtrl,
      options: const MapOptions(
        initialCenter: _medan,
        initialZoom: 13,
        interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.medanflow.app',
          tileProvider: CancellableNetworkTileProvider(),
          maxNativeZoom: 19,
          keepBuffer: 2,
          tileDisplay: const TileDisplay.fadeIn(
            duration: Duration(milliseconds: 200),
          ),
        ),
        MarkerLayer(markers: _buildMapMarkers()),
      ],
    );
  }

  List<Marker> _buildMapMarkers() {
    final markers = [..._angkotMarkers];

    if (_userLatLng != null) {
      markers.add(
        Marker(
          point: _userLatLng!,
          width: 50,
          height: 50,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 44 + _pulseCtrl.value * 8,
                  height: 44 + _pulseCtrl.value * 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _T.b500.withOpacity(0.12 + _pulseCtrl.value * 0.12),
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _T.b600,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(color: _T.b600.withOpacity(0.5), blurRadius: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_destPlace != null) {
      markers.add(
        Marker(
          point: LatLng(_destPlace!.lat, _destPlace!.lon),
          width: 48,
          height: 56,
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _T.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: _T.red.withOpacity(0.5), blurRadius: 12),
                  ],
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Container(
                width: 2.5,
                height: 14,
                decoration: BoxDecoration(
                  color: _T.red,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  Widget _mapFab(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: _T.b700, size: 20),
    ),
  );

  // ─────────────────────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final now = DateTime.now();
    const days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final dateStr =
        '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';

    return Container(
      key: _keyHeader,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo + title
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.directions_bus_filled_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MedFlow',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.white.withOpacity(0.65),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Notification bell
          GestureDetector(
            onTap: () => _push(const NotificationScreen()),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  if (_unread > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF87171),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
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

  // ─────────────────────────────────────────────────────────────
  //  WEATHER CARD
  // ─────────────────────────────────────────────────────────────

  Widget _buildWeatherCard() {
    return AnimatedContainer(
      key: _keyWeather,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _T.navy.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _weatherLoading
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _T.b600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Memuat data cuaca...',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _T.ink3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : _weather == null
          ? const SizedBox.shrink()
          : _buildWeatherContent(),
    );
  }

  Widget _buildWeatherContent() {
    final w = _weather!;
    IconData weatherIcon;
    Color iconColor;
    Color iconBg;
    LinearGradient accentGrad;

    switch (w.icon) {
      case 'rainy':
        weatherIcon = Icons.water_drop_rounded;
        iconColor = const Color(0xFF2563EB);
        iconBg = const Color(0xFFDBEAFE);
        accentGrad = const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        );
        break;
      case 'cloudy':
        weatherIcon = Icons.cloud_rounded;
        iconColor = const Color(0xFF64748B);
        iconBg = const Color(0xFFF1F5F9);
        accentGrad = const LinearGradient(
          colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
        );
        break;
      default:
        weatherIcon = Icons.wb_sunny_rounded;
        iconColor = const Color(0xFFF59E0B);
        iconBg = const Color(0xFFFEF3C7);
        accentGrad = const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
        );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => setState(() => _weatherExpanded = !_weatherExpanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(weatherIcon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _T.ink,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        w.location,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: _T.ink4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _weatherChip(w.temp, accentGrad),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _weatherExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _T.ink4,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 280),
          crossFadeState: _weatherExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: _buildWeatherExpanded(w, iconColor, accentGrad),
        ),
      ],
    );
  }

  Widget _weatherChip(String value, LinearGradient grad) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      gradient: grad,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      value,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
    ),
  );

  Widget _buildWeatherExpanded(
    _WeatherData w,
    Color iconColor,
    LinearGradient grad,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.b50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statItem(Icons.thermostat_rounded, 'Suhu', w.temp, iconColor),
              _vertDivider(),
              _statItem(
                Icons.water_drop_outlined,
                'Kelembapan',
                w.humidity,
                const Color(0xFF0EA5E9),
              ),
              _vertDivider(),
              _statItem(
                Icons.air_rounded,
                'Angin',
                w.windSpeed,
                const Color(0xFF8B5CF6),
              ),
            ],
          ),
          if (w.tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: _T.b100),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.tips_and_updates_outlined,
                    size: 12,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Tips Hari Ini',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _T.ink2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...w.tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 5, right: 7),
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: _T.ink3,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value, Color color) =>
      Expanded(
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _T.ink,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                color: _T.ink4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _vertDivider() => Container(
    width: 1,
    height: 36,
    color: _T.b200,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );

  // ─────────────────────────────────────────────────────────────
  //  ALERT BANNER
  // ─────────────────────────────────────────────────────────────

  Widget _buildAlertBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: _T.redBg.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.red.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: _T.red.withOpacity(0.10), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _T.red.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: _T.red,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _bannerMsg,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showBanner = false),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.close_rounded,
                color: _T.red.withOpacity(0.7),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  TRIP SHEET
  // ─────────────────────────────────────────────────────────────

  Widget _buildTripSheet() {
    return DraggableScrollableSheet(
      controller: _sheetCtrl,
      initialChildSize: _sizeCollapsed,
      minChildSize: _sizeCollapsed,
      maxChildSize: _sizeResults,
      snap: true,
      snapSizes: const [_sizeCollapsed, _sizeSearch, _sizeResults],
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: _T.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A1D4ED8),
                blurRadius: 32,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.zero,
            physics: const ClampingScrollPhysics(),
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _T.ink5,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              if (_sheetPhase == 0) _buildCollapsedContent(),

              if (_sheetPhase >= 1) ...[
                _buildSearchRow(),
                const SizedBox(height: 8),
                if (_suggestions.isNotEmpty || _loadingSugg)
                  _buildSuggestions(),
              ],

              if (_sheetPhase == 3 && _tripResult != null) ...[
                const SizedBox(height: 4),
                _buildTripResults(),
              ],

              const SizedBox(height: 120),
            ],
          ),
        );
      },
    );
  }

  // ── Collapsed content: rute pill + driver login ───────────────
  Widget _buildCollapsedContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Cari rute pill ──────────────────────────────────────
        GestureDetector(
          key: _keyStartTrip,
          onTap: _expandToSearch,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_T.b500, _T.b800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _T.b700.withOpacity(0.40),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.near_me_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mau pergi ke mana?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tap untuk cari rute angkot tercepat',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Driver Login Button ─────────────────────────────────
        GestureDetector(
          onTap: () => _push(const LoginScreen()),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _T.b100, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _T.b500.withOpacity(0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon kiri
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _T.b50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _T.b100),
                  ),
                  child: const Icon(
                    Icons.drive_eta_rounded,
                    color: _T.b600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Label
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Login sebagai Driver',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _T.b700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Akses dashboard & tracking angkot',
                        style: TextStyle(
                          fontSize: 11,
                          color: _T.ink4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge "Portal"
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _T.b50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _T.b200),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Portal',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: _T.b600,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: _T.b600,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Search row ───────────────────────────────────────────────
  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: [
          // Search card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _T.b50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _T.b100, width: 1.5),
            ),
            child: Column(
              children: [
                // Origin
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _T.b100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: _T.b600,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _originIsGps
                          ? GestureDetector(
                              onTap: () {
                                setState(() {
                                  _originIsGps = false;
                                  _originCtrl.clear();
                                  _searchingFor = true;
                                });
                                _originFocus.requestFocus();
                              },
                              child: Text(
                                _originLabel,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: _T.ink,
                                ),
                              ),
                            )
                          : TextField(
                              controller: _originCtrl,
                              focusNode: _originFocus,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: _T.ink,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Cari lokasi asal...',
                                hintStyle: TextStyle(
                                  color: _T.ink4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap: () => setState(() => _searchingFor = true),
                              onChanged: (v) => _onSearchChanged(v, true),
                            ),
                    ),
                    if (!_originIsGps)
                      GestureDetector(
                        onTap: () => setState(() {
                          _originIsGps = true;
                          _originLabel = _userLatLng != null
                              ? 'Lokasi Saya Saat Ini'
                              : 'Lokasi Saya';
                          _originPlace = null;
                          _originCtrl.clear();
                          _suggestions = [];
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _T.b50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _T.b200),
                          ),
                          child: const Icon(
                            Icons.gps_fixed_rounded,
                            size: 14,
                            color: _T.b600,
                          ),
                        ),
                      ),
                  ],
                ),

                // Connector
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Column(
                        children: List.generate(
                          4,
                          (_) => Container(
                            margin: const EdgeInsets.symmetric(vertical: 1.5),
                            width: 2,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _T.b300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _swapPlaces,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _T.card,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: _T.b200, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: _T.b500.withOpacity(0.08),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.swap_vert_rounded,
                            color: _T.b600,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Destination
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _T.redBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.flag_rounded,
                        color: _T.red,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _destCtrl,
                        focusNode: _destFocus,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _T.ink,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Cari tujuan...',
                          hintStyle: TextStyle(
                            color: _T.ink4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () => setState(() => _searchingFor = false),
                        onChanged: (v) => _onSearchChanged(v, false),
                      ),
                    ),
                    if (_destCtrl.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _destCtrl.clear();
                          setState(() {
                            _destPlace = null;
                            _suggestions = [];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: _T.ink3,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Cari button
          GestureDetector(
            onTap: _tripLoading ? null : _fetchTripResults,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_T.b500, _T.b800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _T.b700.withOpacity(0.36),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: _tripLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
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
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          if (_sheetPhase >= 1)
            TextButton(
              onPressed: _collapseSheet,
              child: const Text(
                'Batalkan',
                style: TextStyle(
                  color: _T.ink4,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _swapPlaces() {
    setState(() {
      final tmpPlace = _originPlace;
      final tmpIsGps = _originIsGps;
      final tmpText = _originCtrl.text;

      if (_destPlace != null) {
        _originPlace = _destPlace;
        _originIsGps = false;
        _originLabel = _destPlace!.short;
        _originCtrl.text = _destPlace!.short;
      } else {
        _originPlace = null;
        _originIsGps = false;
        _originLabel = '';
        _originCtrl.clear();
      }

      if (!tmpIsGps && tmpPlace != null) {
        _destPlace = tmpPlace;
        _destCtrl.text = tmpText;
      } else {
        _destPlace = null;
        _destCtrl.clear();
      }
      _suggestions = [];
    });
  }

  // ── Suggestions ──────────────────────────────────────────────
  Widget _buildSuggestions() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.b100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _T.b500.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: _loadingSugg
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _T.b500,
                    ),
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < _suggestions.length; i++) ...[
                    InkWell(
                      onTap: () => _selectPlace(_suggestions[i], _searchingFor),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _searchingFor ? _T.b50 : _T.redBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                i == 0
                                    ? Icons.location_on_rounded
                                    : Icons.place_outlined,
                                size: 17,
                                color: _searchingFor ? _T.b600 : _T.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _suggestions[i].short,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _T.ink,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _suggestions[i].display,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: _T.ink4,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.north_west_rounded,
                              size: 13,
                              color: _T.ink4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i < _suggestions.length - 1)
                      Divider(height: 1, color: _T.b50, indent: 52),
                  ],
                ],
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  TRIP RESULTS
  // ─────────────────────────────────────────────────────────────

  Widget _buildTripResults() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Angkot Tercepat',
            Icons.directions_bus_rounded,
            _T.b600,
            onTap: () => _push(const AngkotTrackingScreen()),
          ),
          const SizedBox(height: 10),
          _buildAngkotSection(),
          const SizedBox(height: 18),

          _sectionHeader(
            'Kondisi Lalu Lintas',
            Icons.grid_view_rounded,
            _T.green,
            onTap: () => _push(const TrafficHeatmapScreen()),
          ),
          const SizedBox(height: 10),
          _buildTrafficSection(),
          const SizedBox(height: 18),

          _sectionHeader(
            'Estimasi Waktu',
            Icons.schedule_rounded,
            _T.orange,
            onTap: () => _push(const TravelTimePredictionScreen()),
          ),
          const SizedBox(height: 10),
          _buildEstimateSection(),
          const SizedBox(height: 16),

          // Cari rute lain
          GestureDetector(
            onTap: () {
              setState(() {
                _sheetPhase = 1;
                _tripResult = null;
              });
              _sheetCtrl.animateTo(
                _sizeSearch,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: _T.b50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _T.b200, width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, size: 16, color: _T.b600),
                  SizedBox(width: 8),
                  Text(
                    'Cari Rute Lain',
                    style: TextStyle(
                      color: _T.b600,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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

  Widget _sectionHeader(
    String title,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: _T.ink,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _T.b50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _T.b100),
            ),
            child: const Text(
              'Detail →',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _T.b600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAngkotSection() {
    final routes = (_tripResult!['routes'] as List?) ?? [];
    if (routes.isEmpty)
      return _emptyCard('Belum ada angkot aktif di rute ini.');
    return Column(
      children: routes.take(2).map<Widget>((r) {
        final full = (r['crowd_status'] ?? '') == 'Penuh';
        final sCo = full ? _T.red : _T.green;
        final sBg = full ? _T.redBg : _T.greenBg;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _T.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _T.ink5, width: 1),
            boxShadow: [
              BoxShadow(
                color: _T.b500.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_T.b100, _T.b200]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.directions_bus_filled_rounded,
                  color: _T.b700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Angkot ${r['angkot_number'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _T.ink,
                      ),
                    ),
                    Text(
                      r['route_name'] ?? 'Rute Medan',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: _T.ink3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: sBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (r['crowd_status'] ?? '-').toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: sCo,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${r['eta_minutes'] ?? '-'} mnt',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: _T.ink2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrafficSection() {
    final hm = _tripResult!['heatmap'];
    final data = (hm?['data'] as List?) ?? [];
    final total = data.length;
    int macet = 0, padat = 0, lancar = 0;
    for (final d in data) {
      switch (d['congestion_level']) {
        case 'macet':
          macet++;
          break;
        case 'padat':
          padat++;
          break;
        default:
          lancar++;
          break;
      }
    }
    final pM = total > 0 ? macet / total : 0.0;
    final pP = total > 0 ? padat / total : 0.0;
    final pL = total > 0 ? lancar / total : 1.0;

    String statusText;
    Color statusColor;
    IconData statusIcon;
    if (pM > 0.4) {
      statusText = 'Kondisi Macet';
      statusColor = _T.red;
      statusIcon = Icons.traffic_rounded;
    } else if (pP > 0.4) {
      statusText = 'Padat Merayap';
      statusColor = _T.orange;
      statusIcon = Icons.slow_motion_video_rounded;
    } else {
      statusText = 'Cukup Lancar';
      statusColor = _T.green;
      statusIcon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.ink5, width: 1),
        boxShadow: [
          BoxShadow(
            color: _T.b500.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              Text(
                '$total titik',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: _T.ink4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  _barSeg(pM, _T.red),
                  _barSeg(pP, _T.orange),
                  _barSeg(pL, _T.green),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _dot(_T.red, 'Macet'),
              const SizedBox(width: 14),
              _dot(_T.orange, 'Padat'),
              const SizedBox(width: 14),
              _dot(_T.green, 'Lancar'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barSeg(double flex, Color c) => Expanded(
    flex: (flex * 100).round().clamp(1, 100),
    child: ColoredBox(color: c),
  );

  Widget _dot(Color c, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          color: _T.ink3,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _buildEstimateSection() {
    final est = _tripResult!['estimate'] as Map<String, dynamic>?;
    if (est == null) return _emptyCard('Data estimasi belum tersedia.');

    final menit = (est['predicted_time'] as String? ?? '0').replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.ink5, width: 1),
        boxShadow: [
          BoxShadow(
            color: _T.b500.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_T.b500, _T.b800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _T.b700.withOpacity(0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  menit,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const Text(
                  'MENIT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
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
                  est['congestion_level'] as String? ?? 'Normal',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _T.ink,
                  ),
                ),
                const SizedBox(height: 5),
                _infoRow(
                  Icons.straighten_rounded,
                  'Jarak',
                  '${est['distance'] ?? '-'}',
                ),
                const SizedBox(height: 3),
                _infoRow(
                  Icons.timer_outlined,
                  'Delay',
                  '${est['delay'] ?? '-'}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 13, color: _T.ink4),
      const SizedBox(width: 4),
      Text(
        '$label: ',
        style: const TextStyle(
          fontSize: 11,
          color: _T.ink4,
          fontWeight: FontWeight.w600,
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          fontSize: 11.5,
          color: _T.ink3,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _emptyCard(String msg) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _T.b50,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _T.b100),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, size: 16, color: _T.ink4),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            msg,
            style: const TextStyle(
              fontSize: 12.5,
              color: _T.ink3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  // ─────────────────────────────────────────────────────────────
  //  BOTTOM NAV
  // ─────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_T.bg.withOpacity(0), _T.bg, _T.bg],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _T.ink5, width: 1),
            boxShadow: [
              BoxShadow(
                color: _T.b600.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _navItem(0, Icons.home_rounded, 'Beranda', onTap: _collapseSheet),
              _navItem(
                1,
                Icons.alt_route_rounded,
                'Rute',
                onTap: () => _push(const RouteRecommendationScreen()),
              ),
              // Center FAB — Angkot
              GestureDetector(
                key: _keyNavAngkot,
                onTap: () => _push(const AngkotTrackingScreen()),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_T.b500, _T.b800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _T.b700.withOpacity(0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              _navItem(
                3,
                Icons.show_chart_rounded,
                'Lalu Lintas',
                key: _keyNavTraffic,
                onTap: () => _push(const TrafficHeatmapScreen()),
              ),
              _navItem(
                4,
                Icons.schedule_rounded,
                'Estimasi',
                onTap: () => _push(const TravelTimePredictionScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    int idx,
    IconData icon,
    String label, {
    Key? key,
    required VoidCallback onTap,
  }) {
    final on = _activeNav == idx;
    return Expanded(
      child: GestureDetector(
        key: key,
        onTap: () {
          setState(() => _activeNav = idx);
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: on ? _T.b50 : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: on ? _T.b600 : _T.ink4, size: 20),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: on ? _T.b600 : _T.ink4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _push(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
