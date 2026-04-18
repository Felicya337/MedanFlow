import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
// Palette
// ─────────────────────────────────────────────
class _P {
  static const b50  = Color(0xFFEFF6FF);
  static const b100 = Color(0xFFDBEAFE);
  static const b200 = Color(0xFFBFDBFE);
  static const b300 = Color(0xFF93C5FD);
  static const b400 = Color(0xFF60A5FA);
  static const b500 = Color(0xFF3B82F6);
  static const b600 = Color(0xFF2563EB);
  static const b700 = Color(0xFF1D4ED8);
  static const b800 = Color(0xFF1E40AF);
  static const bg   = Color(0xFFEEF4FF);
  static const card = Colors.white;
  static const ink  = Color(0xFF0F172A);
  static const ink2 = Color(0xFF334155);
  static const ink3 = Color(0xFF64748B);
  static const ink4 = Color(0xFF94A3B8);
  static const dark = Color(0xFF0F2878);
}

// ══════════════════════════════════════════════════════════════
//  ANIMATED WEATHER ICONS
// ══════════════════════════════════════════════════════════════

class RainyWeatherIcon extends StatefulWidget {
  final double size;
  const RainyWeatherIcon({super.key, this.size = 40});
  @override
  State<RainyWeatherIcon> createState() => _RainyWeatherIconState();
}
class _RainyWeatherIconState extends State<RainyWeatherIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => CustomPaint(size: Size(widget.size, widget.size), painter: _RainyPainter(t: _ctrl.value)),
  );
}

class _RainyPainter extends CustomPainter {
  final double t;
  _RainyPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final floatY = math.sin(t * math.pi * 2) * 3.5;
    _drawCloud(canvas, w, h, floatY, Paint()..color = Colors.white.withOpacity(0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    _drawCloud(canvas, w, h, floatY, Paint()..shader = LinearGradient(colors: [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.72)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(w * 0.08, h * 0.08, w * 0.84, h * 0.56)));
    final dropPositions = [Offset(w*0.24,h*0.62),Offset(w*0.38,h*0.65),Offset(w*0.53,h*0.62),Offset(w*0.68,h*0.65),Offset(w*0.31,h*0.76),Offset(w*0.60,h*0.76)];
    final delays = [0.0,0.20,0.40,0.60,0.10,0.50];
    for (int i = 0; i < dropPositions.length; i++) {
      final progress = (t + delays[i]) % 1.0;
      final opacity = progress < 0.65 ? (progress < 0.1 ? progress / 0.1 : 1.0) : (1.0 - progress) / 0.35;
      final yOff = progress * h * 0.25;
      final p1 = dropPositions[i].translate(0, yOff + floatY);
      final p2 = p1.translate(-h * 0.05, h * 0.12);
      canvas.drawLine(p1, p2, Paint()..color = Colors.white.withOpacity((opacity * 0.88).clamp(0,1))..strokeWidth = 2.4..strokeCap = StrokeCap.round);
    }
  }
  void _drawCloud(Canvas canvas, double w, double h, double floatY, Paint paint) {
    final cx = w*0.50; final cy = h*0.30 + floatY;
    final path = ui.Path();
    path.addOval(Rect.fromCenter(center: Offset(cx,cy), width: w*0.58, height: h*0.32));
    path.addOval(Rect.fromCenter(center: Offset(cx-w*0.19,cy+h*0.05), width: w*0.30, height: h*0.24));
    path.addOval(Rect.fromCenter(center: Offset(cx+w*0.19,cy+h*0.06), width: w*0.26, height: h*0.20));
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx-w*0.29,cy-h*0.02,cx+w*0.29,cy+h*0.16), const Radius.circular(10)));
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(_RainyPainter old) => old.t != t;
}

class CloudySunIcon extends StatefulWidget {
  final double size;
  const CloudySunIcon({super.key, this.size = 40});
  @override State<CloudySunIcon> createState() => _CloudySunIconState();
}
class _CloudySunIconState extends State<CloudySunIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => CustomPaint(size: Size(widget.size, widget.size), painter: _CloudySunPainter(t: _ctrl.value)),
  );
}

class _CloudySunPainter extends CustomPainter {
  final double t;
  _CloudySunPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final floatY = math.sin(t * math.pi * 2) * 3.0;
    final sunCenter = Offset(w*0.30, h*0.34 + floatY*0.4);
    canvas.drawCircle(sunCenter, w*0.22, Paint()..color = const Color(0xFFFDE68A).withOpacity(0.30)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    final rayPaint = Paint()..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final angle = (i/8)*math.pi*2 + t*math.pi*2; final isLong = i%2==0;
      rayPaint..color = const Color(0xFFFDE68A).withOpacity(isLong?0.9:0.5)..strokeWidth = isLong?2.2:1.6;
      canvas.drawLine(sunCenter.translate(math.cos(angle)*w*0.16, math.sin(angle)*w*0.16), sunCenter.translate(math.cos(angle)*w*(isLong?0.26:0.22), math.sin(angle)*w*(isLong?0.26:0.22)), rayPaint);
    }
    canvas.drawCircle(sunCenter, w*0.12, Paint()..shader = RadialGradient(colors: [const Color(0xFFFCD34D), const Color(0xFFF59E0B)]).createShader(Rect.fromCircle(center: sunCenter, radius: w*0.12)));
    final cloudCx = w*0.57; final cloudCy = h*0.52 + floatY;
    _drawCloud(canvas, cloudCx, cloudCy, w, h, Paint()..color = Colors.white.withOpacity(0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    _drawCloud(canvas, cloudCx, cloudCy, w, h, Paint()..shader = LinearGradient(colors: [Colors.white.withOpacity(0.97), Colors.white.withOpacity(0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(Rect.fromLTWH(cloudCx-w*0.28, cloudCy-h*0.18, w*0.56, h*0.40)));
  }
  void _drawCloud(Canvas canvas, double cx, double cy, double w, double h, Paint paint) {
    final path = ui.Path();
    path.addOval(Rect.fromCenter(center: Offset(cx,cy), width: w*0.48, height: h*0.26));
    path.addOval(Rect.fromCenter(center: Offset(cx-w*0.16,cy+h*0.04), width: w*0.26, height: h*0.20));
    path.addOval(Rect.fromCenter(center: Offset(cx+w*0.15,cy+h*0.05), width: w*0.22, height: h*0.17));
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx-w*0.24,cy,cx+w*0.24,cy+h*0.14), const Radius.circular(8)));
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(_CloudySunPainter old) => old.t != t;
}

class SunnyIcon extends StatefulWidget {
  final double size;
  const SunnyIcon({super.key, this.size = 40});
  @override State<SunnyIcon> createState() => _SunnyIconState();
}
class _SunnyIconState extends State<SunnyIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => CustomPaint(size: Size(widget.size, widget.size), painter: _SunnyPainter(t: _ctrl.value)),
  );
}

class _SunnyPainter extends CustomPainter {
  final double t;
  _SunnyPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final center = Offset(w*0.5, h*0.5);
    final pulse = math.sin(t*math.pi*2)*0.07+1.0;
    canvas.drawCircle(center, w*0.44*pulse, Paint()..color = const Color(0xFFFDE68A).withOpacity(0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
    canvas.drawCircle(center, w*0.33*pulse, Paint()..color = const Color(0xFFFCD34D).withOpacity(0.28)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    final rayAngle = t*math.pi*2;
    for (int i = 0; i < 12; i++) {
      final angle = (i/12)*math.pi*2+rayAngle; final isLong = i%2==0;
      canvas.drawLine(center.translate(math.cos(angle)*w*0.28,math.sin(angle)*w*0.28), center.translate(math.cos(angle)*w*(isLong?0.44:0.38),math.sin(angle)*w*(isLong?0.44:0.38)),
        Paint()..color = const Color(0xFFFDE68A).withOpacity(isLong?0.92:0.55)..strokeWidth = isLong?2.6:1.8..strokeCap = StrokeCap.round);
    }
    canvas.drawCircle(center, w*0.23, Paint()..shader = RadialGradient(colors: [const Color(0xFFFBBF24),const Color(0xFFF59E0B),const Color(0xFFD97706)],stops: const [0.0,0.65,1.0]).createShader(Rect.fromCircle(center: center, radius: w*0.23)));
    canvas.drawCircle(center.translate(-w*0.07,-h*0.07), w*0.09, Paint()..color = Colors.white.withOpacity(0.42));
  }
  @override bool shouldRepaint(_SunnyPainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════════════
//  DESTINATION INPUT BOTTOM SHEET
// ══════════════════════════════════════════════════════════════

class _DestinationSheet extends StatefulWidget {
  const _DestinationSheet();
  @override
  State<_DestinationSheet> createState() => _DestinationSheetState();
}

class _DestinationSheetState extends State<_DestinationSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  // Saran destinasi populer di Medan
  final List<Map<String, dynamic>> _suggestions = [
    {'icon': Icons.store_rounded,       'color': const Color(0xFF0EA5E9), 'name': 'Sun Plaza',          'sub': 'Jl. Zainul Arifin, Medan'},
    {'icon': Icons.local_hospital_rounded,'color': const Color(0xFFEF4444),'name': 'RS Adam Malik',     'sub': 'Jl. Bunga Lau, Medan Tuntungan'},
    {'icon': Icons.school_rounded,      'color': const Color(0xFFF59E0B), 'name': 'USU',                'sub': 'Jl. Universitas, Padang Bulan'},
    {'icon': Icons.train_rounded,       'color': const Color(0xFF8B5CF6), 'name': 'Stasiun Medan',      'sub': 'Jl. Prof. HM. Yamin, Medan'},
    {'icon': Icons.flight_rounded,      'color': const Color(0xFF10B981), 'name': 'Bandara Kualanamu', 'sub': 'Deli Serdang, Sumatera Utara'},
    {'icon': Icons.store_mall_directory_rounded,'color': const Color(0xFFEC4899),'name': 'Medan Mall', 'sub': 'Jl. M.T. Haryono, Medan'},
    {'icon': Icons.mosque_rounded,      'color': const Color(0xFF14B8A6), 'name': 'Masjid Raya Medan', 'sub': 'Jl. Sisingamangaraja, Medan'},
    {'icon': Icons.directions_bus_rounded,'color': const Color(0xFFF97316),'name': 'Terminal Pinang Baris','sub': 'Jl. Pinang Baris, Medan'},
  ];

  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = _suggestions;
    _ctrl.addListener(_onSearch);
    Future.delayed(const Duration(milliseconds: 200), () => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _ctrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _suggestions
          : _suggestions.where((s) =>
              s['name'].toString().toLowerCase().contains(q) ||
              s['sub'].toString().toLowerCase().contains(q)).toList();
    });
  }

  void _selectDestination(String name) {
    Navigator.pop(context);
    // Arahkan ke RouteRecommendationScreen dengan tujuan terpilih
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RouteRecommendationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: _P.b100, borderRadius: BorderRadius.circular(10)),
          ),

          // Judul
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Mau pergi ke mana?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _P.ink)),
            ),
          ),

          // Search field
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: _P.b50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _P.b200, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: _P.b500, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _P.ink),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Cari tujuan atau alamat...',
                      hintStyle: TextStyle(color: _P.ink4, fontWeight: FontWeight.w500),
                    ),
                    onSubmitted: (v) { if (v.isNotEmpty) _selectDestination(v); },
                  ),
                ),
                if (_ctrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () { _ctrl.clear(); setState(() => _filtered = _suggestions); },
                    child: const Icon(Icons.close_rounded, color: _P.ink4, size: 18),
                  ),
              ],
            ),
          ),

          // Label saran
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('TUJUAN POPULER',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _P.ink4, letterSpacing: 0.8)),
            ),
          ),

          // Daftar saran
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: _filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Tidak ditemukan', style: TextStyle(color: _P.ink4)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: _P.b50),
                    itemBuilder: (context, i) {
                      final item = _filtered[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                        leading: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                        ),
                        title: Text(item['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: _P.ink)),
                        subtitle: Text(item['sub'] as String,
                          style: const TextStyle(fontSize: 11.5, color: _P.ink3)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: _P.ink4),
                        onTap: () => _selectDestination(item['name'] as String),
                      );
                    },
                  ),
          ),

          // Safe area padding bawah
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
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
  // ── State ────────────────────────────────────────────────────
  int _unreadNotif = 0;
  bool _showCriticalBanner = false;
  String _bannerMessage = '';

  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;

  int _activeNav = 0;

  // ── GPS & Map ────────────────────────────────────────────────
  final MapController _mapController = MapController();
  Position? _userPosition;
  final LatLng _medanCenter = const LatLng(3.5952, 98.6722);

  // ── Onboarding ───────────────────────────────────────────────
  final _keyNotif        = GlobalKey();
  final _keyWeather      = GlobalKey();
  final _keyQuickRute    = GlobalKey();
  final _keyQuickAngkot  = GlobalKey();
  final _keyTrafficStrip = GlobalKey();
  static const _kOnboardingDone = 'onboarding_done';
  bool _onboardingDone = false;

  @override
  void initState() {
    super.initState();
    _checkNotifications();
    _fetchWeather();
    _determinePosition();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowOnboarding());
  }

  // ── GPS ──────────────────────────────────────────────────────
  Future<void> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() => _userPosition = position);
        _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
      }
    }
  }

  // ── Onboarding ───────────────────────────────────────────────
  Future<void> _maybeShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyDone = prefs.getBool(_kOnboardingDone) ?? false;
    if (alreadyDone) { if (mounted) setState(() => _onboardingDone = true); return; }
    if (mounted) Future.delayed(const Duration(milliseconds: 400), () { if (mounted && !_onboardingDone) _startOnboarding(); });
  }

  void _startOnboarding() {
    OnboardingOverlay.show(
      context: context,
      steps: [
        OnboardingStep(targetKey: _keyNotif,       icon: OnboardingIcon.notification, title: 'Notifikasi & Peringatan',    description: 'Dapatkan alert kemacetan parah dan info penting secara real-time.',         padding: const EdgeInsets.all(6)),
        OnboardingStep(targetKey: _keyWeather,     icon: OnboardingIcon.weather,      title: 'Cuaca Real-time Medan',      description: 'Pantau suhu, kelembaban, dan angin agar perjalananmu lebih siap.',          padding: const EdgeInsets.all(8)),
        OnboardingStep(targetKey: _keyQuickRute,   icon: OnboardingIcon.route,        title: 'Rute Pintar',                description: 'Temukan jalur tercepat di Medan dengan rekomendasi berbasis AI.',            padding: const EdgeInsets.all(6)),
        OnboardingStep(targetKey: _keyQuickAngkot, icon: OnboardingIcon.angkot,       title: 'Live Angkot',                description: 'Posisi angkot real-time beserta estimasi waktu kedatangan.',                 padding: const EdgeInsets.all(6)),
        OnboardingStep(targetKey: _keyTrafficStrip,icon: OnboardingIcon.traffic,      title: 'Prediksi 30 Menit ke Depan',description: 'Cek prakiraan kemacetan 30 menit ke depan untuk waktu terbaik berangkat.',  padding: const EdgeInsets.all(8)),
      ],
      onFinished: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kOnboardingDone, true);
        if (mounted) setState(() => _onboardingDone = true);
      },
    );
  }

  // ── Notifications ────────────────────────────────────────────
  Future<void> _checkNotifications() async {
    try {
      final data = await ApiService().getNotifications();
      setState(() {
        _unreadNotif = data['unread_count'] as int;
        if (_unreadNotif > 0) { _showCriticalBanner = true; _bannerMessage = data['alerts'][0]['message'] as String; }
      });
    } catch (e) { debugPrint('Check Notif Failed: $e'); }
  }

  // ── Fetch Cuaca ──────────────────────────────────────────────
  Future<void> _fetchWeather() async {
    try {
      final response = await http.get(Uri.parse('${ApiService().baseUrl}/weather/current'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() { _weatherData = decoded; _isLoadingWeather = false; });
      }
    } catch (e) { debugPrint('Fetch Weather Failed: $e'); setState(() => _isLoadingWeather = false); }
  }

  // ── Buka sheet input tujuan ───────────────────────────────────
  void _openDestinationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const _DestinationSheet(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // ── 1. PETA FULL-SCREEN ──────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _medanCenter, initialZoom: 14.0),
            children: [
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/${ApiService.mapboxTrafficStyle}/tiles/256/{z}/{x}/{y}@2x?access_token=${ApiService.mapboxToken}',
                additionalOptions: const {'accessToken': ApiService.mapboxToken, 'id': ApiService.mapboxTrafficStyle},
                userAgentPackageName: 'com.medanflow.app',
              ),
              if (_userPosition != null)
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                    width: 52, height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, color: _P.b600,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: _P.b600.withOpacity(0.45), blurRadius: 14)],
                      ),
                      child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ]),
            ],
          ),

          // ── 2. GRADIENT OVERLAY ATAS ─────────────────────────
          Positioned(
            top: 0, left: 0, right: 0, height: 200,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.50), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // ── 3. HEADER + CUACA + BANNER ───────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                if (_showCriticalBanner) _buildAlertBanner(),
                _buildWeatherCard(),
              ],
            ),
          ),

          // ── 4. ZOOM + LOKASI SAYA (kanan tengah) ─────────────
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.40,
            child: Column(
              children: [
                _buildMapBtn(Icons.add_rounded,
                    () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
                const SizedBox(height: 8),
                _buildMapBtn(Icons.remove_rounded,
                    () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
                const SizedBox(height: 8),
                _buildMapBtn(Icons.my_location_rounded, () {
                  if (_userPosition != null) {
                    _mapController.move(LatLng(_userPosition!.latitude, _userPosition!.longitude), 15.0);
                  }
                }),
              ],
            ),
          ),

          // ── 5. FLOATING "MAU PERGI KE MANA?" ─────────────────
          // Menempel tepat di atas navbar, mirip screenshot
          Positioned(
            bottom: 100, // tepat di atas navbar (tinggi navbar ~90-100)
            left: 20,
            right: 20,
            child: _buildDestinationBar(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Destination Bar ───────────────────────────────────────────
  Widget _buildDestinationBar() {
    return GestureDetector(
      key: _keyTrafficStrip, // reuse key untuk onboarding
      onTap: _openDestinationSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: _P.b600,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: _P.b700.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mau pergi ke mana?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                  SizedBox(height: 2),
                  Text('Tap untuk cari rute angkot tercepat',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _P.b100, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 8)],
        ),
        child: Icon(icon, color: _P.b600, size: 20),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    final now = DateTime.now();
    const days   = ['Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'];
    const months = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
    final dateStr = '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(colors: [Colors.white, Color(0xFFBAE6FD)]).createShader(b),
                child: const Text('MedFlow',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
              ),
              Text(dateStr,
                style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w600)),
            ],
          ),
          Container(key: _keyNotif, child: _notifBtn()),
        ],
      ),
    );
  }

  Widget _notifBtn() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.30), width: 1.5),
        ),
        child: Stack(
          children: [
            const Center(child: Icon(Icons.notifications_none_outlined, color: Colors.white, size: 20)),
            if (_unreadNotif > 0)
              Positioned(top: 8, right: 8,
                child: Container(width: 9, height: 9,
                  decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)))),
          ],
        ),
      ),
    );
  }

  // ── Alert Banner ──────────────────────────────────────────────
  Widget _buildAlertBanner() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: _showCriticalBanner
          ? Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2).withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_bannerMessage, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12, fontWeight: FontWeight.w700, height: 1.4))),
                  GestureDetector(
                    onTap: () => setState(() => _showCriticalBanner = false),
                    child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('✕', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700))),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ── Weather Card — glassmorphism kompak di atas peta ──────────
  Widget _buildWeatherCard() {
    return KeyedSubtree(
      key: _keyWeather,
      child: _isLoadingWeather
          ? Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
              ),
              child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            )
          : _weatherData == null ? const SizedBox.shrink()
          : Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.28), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  SizedBox(width: 40, height: 40, child: _buildWeatherIcon(_weatherData!['icon'] as String)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_weatherData!['condition'] as String,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(_weatherData!['location'] as String,
                          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.70), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  // Suhu
                  RichText(text: TextSpan(children: [
                    TextSpan(text: (_weatherData!['temp'] as String).replaceAll('°C',''),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                    const TextSpan(text: '°C',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white60)),
                  ])),
                  // Chevron (opsional — bisa dihapus)
                  const SizedBox(width: 6),
                  Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withOpacity(0.60), size: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildWeatherIcon(String iconType) {
    switch (iconType) {
      case 'rainy':  return const RainyWeatherIcon(size: 40);
      case 'cloudy': return const CloudySunIcon(size: 40);
      default:       return const SunnyIcon(size: 40);
    }
  }

  // ── Bottom Nav (tidak berubah) ────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [_P.bg.withOpacity(0), _P.bg, _P.bg],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _P.b500.withOpacity(0.14), width: 1.5),
            boxShadow: [
              BoxShadow(color: _P.b500.withOpacity(0.14), blurRadius: 32, offset: const Offset(0, 8)),
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              _nbItem(0, Icons.home_rounded,       'Beranda',    onTap: () {}),
              _nbItem(1, Icons.search_rounded,     'Rute Pintar',onTap: () => _push(const RouteRecommendationScreen())),
              _nbFab(),
              _nbItem(3, Icons.show_chart_rounded, 'Prediksi',   onTap: () => _push(const TrafficHeatmapScreen())),
              _nbItem(4, Icons.lock_outline_rounded,'Login',     onTap: () => _push(const LoginScreen())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nbItem(int idx, IconData icon, String label, {required VoidCallback onTap}) {
    final on = _activeNav == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () { setState(() => _activeNav = idx); onTap(); },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: on ? _P.b50 : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: on ? _P.b600 : _P.ink4, size: 20),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: on ? _P.b600 : _P.ink4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nbFab() {
    return GestureDetector(
      onTap: () => _push(const AngkotTrackingScreen()),
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_P.b500, _P.b700], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: _P.b600.withOpacity(0.40), blurRadius: 18, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  void _push(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}