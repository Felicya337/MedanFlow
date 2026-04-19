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

// ══════════════════════════════════════════════════════════════
//  ANIMATED WEATHER ICONS (tidak diubah)
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
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _RainyPainter(t: _ctrl.value),
    ),
  );
}

class _RainyPainter extends CustomPainter {
  final double t;
  _RainyPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final floatY = math.sin(t * math.pi * 2) * 3.5;
    _drawCloud(
      canvas,
      w,
      h,
      floatY,
      Paint()
        ..color = Colors.white.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    _drawCloud(
      canvas,
      w,
      h,
      floatY,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.72),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(w * 0.08, h * 0.08, w * 0.84, h * 0.56)),
    );
    final dropPositions = [
      Offset(w * 0.24, h * 0.62),
      Offset(w * 0.38, h * 0.65),
      Offset(w * 0.53, h * 0.62),
      Offset(w * 0.68, h * 0.65),
      Offset(w * 0.31, h * 0.76),
      Offset(w * 0.60, h * 0.76),
    ];
    final delays = [0.0, 0.20, 0.40, 0.60, 0.10, 0.50];
    for (int i = 0; i < dropPositions.length; i++) {
      final progress = (t + delays[i]) % 1.0;
      final opacity = progress < 0.65
          ? (progress < 0.1 ? progress / 0.1 : 1.0)
          : (1.0 - progress) / 0.35;
      final yOff = progress * h * 0.25;
      final p1 = dropPositions[i].translate(0, yOff + floatY);
      final p2 = p1.translate(-h * 0.05, h * 0.12);
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = Colors.white.withOpacity((opacity * 0.88).clamp(0, 1))
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawCloud(
    Canvas canvas,
    double w,
    double h,
    double floatY,
    Paint paint,
  ) {
    final cx = w * 0.50;
    final cy = h * 0.30 + floatY;
    final path = ui.Path();
    path.addOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: w * 0.58,
        height: h * 0.32,
      ),
    );
    path.addOval(
      Rect.fromCenter(
        center: Offset(cx - w * 0.19, cy + h * 0.05),
        width: w * 0.30,
        height: h * 0.24,
      ),
    );
    path.addOval(
      Rect.fromCenter(
        center: Offset(cx + w * 0.19, cy + h * 0.06),
        width: w * 0.26,
        height: h * 0.20,
      ),
    );
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          cx - w * 0.29,
          cy - h * 0.02,
          cx + w * 0.29,
          cy + h * 0.16,
        ),
        const Radius.circular(10),
      ),
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_RainyPainter old) => old.t != t;
}

class CloudySunIcon extends StatefulWidget {
  final double size;
  const CloudySunIcon({super.key, this.size = 40});
  @override
  State<CloudySunIcon> createState() => _CloudySunIconState();
}

class _CloudySunIconState extends State<CloudySunIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _CloudySunPainter(t: _ctrl.value),
    ),
  );
}

class _CloudySunPainter extends CustomPainter {
  final double t;
  _CloudySunPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final floatY = math.sin(t * math.pi * 2) * 3.0;
    final sunCenter = Offset(w * 0.30, h * 0.34 + floatY * 0.4);
    canvas.drawCircle(
      sunCenter,
      w * 0.22,
      Paint()
        ..color = const Color(0xFFFDE68A).withOpacity(0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    final rayPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2 + t * math.pi * 2;
      final isLong = i % 2 == 0;
      rayPaint
        ..color = const Color(0xFFFDE68A).withOpacity(isLong ? 0.9 : 0.5)
        ..strokeWidth = isLong ? 2.2 : 1.6;
      canvas.drawLine(
        sunCenter.translate(
          math.cos(angle) * w * 0.16,
          math.sin(angle) * w * 0.16,
        ),
        sunCenter.translate(
          math.cos(angle) * w * (isLong ? 0.26 : 0.22),
          math.sin(angle) * w * (isLong ? 0.26 : 0.22),
        ),
        rayPaint,
      );
    }
    canvas.drawCircle(
      sunCenter,
      w * 0.12,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFCD34D), const Color(0xFFF59E0B)],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: w * 0.12)),
    );
    final cloudCx = w * 0.57;
    final cloudCy = h * 0.52 + floatY;
    _drawCloud(
      canvas,
      cloudCx,
      cloudCy,
      w,
      h,
      Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    _drawCloud(
      canvas,
      cloudCx,
      cloudCy,
      w,
      h,
      Paint()
        ..shader =
            LinearGradient(
              colors: [
                Colors.white.withOpacity(0.97),
                Colors.white.withOpacity(0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(
              Rect.fromLTWH(
                cloudCx - w * 0.28,
                cloudCy - h * 0.18,
                w * 0.56,
                h * 0.40,
              ),
            ),
    );
  }

  void _drawCloud(
    Canvas canvas,
    double cx,
    double cy,
    double w,
    double h,
    Paint paint,
  ) {
    final path = ui.Path();
    path.addOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: w * 0.48,
        height: h * 0.26,
      ),
    );
    path.addOval(
      Rect.fromCenter(
        center: Offset(cx - w * 0.16, cy + h * 0.04),
        width: w * 0.26,
        height: h * 0.20,
      ),
    );
    path.addOval(
      Rect.fromCenter(
        center: Offset(cx + w * 0.15, cy + h * 0.05),
        width: w * 0.22,
        height: h * 0.17,
      ),
    );
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - w * 0.24, cy, cx + w * 0.24, cy + h * 0.14),
        const Radius.circular(8),
      ),
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CloudySunPainter old) => old.t != t;
}

class SunnyIcon extends StatefulWidget {
  final double size;
  const SunnyIcon({super.key, this.size = 40});
  @override
  State<SunnyIcon> createState() => _SunnyIconState();
}

class _SunnyIconState extends State<SunnyIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _SunnyPainter(t: _ctrl.value),
    ),
  );
}

class _SunnyPainter extends CustomPainter {
  final double t;
  _SunnyPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);
    final pulse = math.sin(t * math.pi * 2) * 0.07 + 1.0;
    canvas.drawCircle(
      center,
      w * 0.44 * pulse,
      Paint()
        ..color = const Color(0xFFFDE68A).withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawCircle(
      center,
      w * 0.33 * pulse,
      Paint()
        ..color = const Color(0xFFFCD34D).withOpacity(0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    final rayAngle = t * math.pi * 2;
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * math.pi * 2 + rayAngle;
      final isLong = i % 2 == 0;
      canvas.drawLine(
        center.translate(
          math.cos(angle) * w * 0.28,
          math.sin(angle) * w * 0.28,
        ),
        center.translate(
          math.cos(angle) * w * (isLong ? 0.44 : 0.38),
          math.sin(angle) * w * (isLong ? 0.44 : 0.38),
        ),
        Paint()
          ..color = const Color(0xFFFDE68A).withOpacity(isLong ? 0.92 : 0.55)
          ..strokeWidth = isLong ? 2.6 : 1.8
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(
      center,
      w * 0.23,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFBBF24),
            const Color(0xFFF59E0B),
            const Color(0xFFD97706),
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: w * 0.23)),
    );
    canvas.drawCircle(
      center.translate(-w * 0.07, -h * 0.07),
      w * 0.09,
      Paint()..color = Colors.white.withOpacity(0.42),
    );
  }

  @override
  bool shouldRepaint(_SunnyPainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════════════
//  DESTINATION INPUT BOTTOM SHEET (tidak diubah)
// ══════════════════════════════════════════════════════════════

class _DestinationSheet extends StatefulWidget {
  const _DestinationSheet();
  @override
  State<_DestinationSheet> createState() => _DestinationSheetState();
}

class _DestinationSheetState extends State<_DestinationSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  final List<Map<String, dynamic>> _suggestions = [
    {
      'icon': Icons.store_rounded,
      'color': const Color(0xFF0EA5E9),
      'name': 'Sun Plaza',
      'sub': 'Jl. Zainul Arifin, Medan',
    },
    {
      'icon': Icons.local_hospital_rounded,
      'color': const Color(0xFFEF4444),
      'name': 'RS Adam Malik',
      'sub': 'Jl. Bunga Lau, Medan Tuntungan',
    },
    {
      'icon': Icons.school_rounded,
      'color': const Color(0xFFF59E0B),
      'name': 'USU',
      'sub': 'Jl. Universitas, Padang Bulan',
    },
    {
      'icon': Icons.train_rounded,
      'color': const Color(0xFF8B5CF6),
      'name': 'Stasiun Medan',
      'sub': 'Jl. Prof. HM. Yamin, Medan',
    },
    {
      'icon': Icons.flight_rounded,
      'color': const Color(0xFF10B981),
      'name': 'Bandara Kualanamu',
      'sub': 'Deli Serdang, Sumatera Utara',
    },
    {
      'icon': Icons.store_mall_directory_rounded,
      'color': const Color(0xFFEC4899),
      'name': 'Medan Mall',
      'sub': 'Jl. M.T. Haryono, Medan',
    },
    {
      'icon': Icons.mosque_rounded,
      'color': const Color(0xFF14B8A6),
      'name': 'Masjid Raya Medan',
      'sub': 'Jl. Sisingamangaraja, Medan',
    },
    {
      'icon': Icons.directions_bus_rounded,
      'color': const Color(0xFFF97316),
      'name': 'Terminal Pinang Baris',
      'sub': 'Jl. Pinang Baris, Medan',
    },
  ];

  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = _suggestions;
    _ctrl.addListener(_onSearch);
    Future.delayed(
      const Duration(milliseconds: 200),
      () => _focus.requestFocus(),
    );
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
          : _suggestions
                .where(
                  (s) =>
                      s['name'].toString().toLowerCase().contains(q) ||
                      s['sub'].toString().toLowerCase().contains(q),
                )
                .toList();
    });
  }

  void _selectDestination(String name) {
    Navigator.pop(context);
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
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _P.b100,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mau pergi ke mana?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _P.ink,
                ),
              ),
            ),
          ),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _P.ink,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Cari tujuan atau alamat...',
                      hintStyle: TextStyle(
                        color: _P.ink4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onSubmitted: (v) {
                      if (v.isNotEmpty) _selectDestination(v);
                    },
                  ),
                ),
                if (_ctrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _ctrl.clear();
                      setState(() => _filtered = _suggestions);
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: _P.ink4,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'TUJUAN POPULER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _P.ink4,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: _filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Tidak ditemukan',
                      style: TextStyle(color: _P.ink4),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: _P.b50),
                    itemBuilder: (context, i) {
                      final item = _filtered[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 0,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: item['color'] as Color,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: _P.ink,
                          ),
                        ),
                        subtitle: Text(
                          item['sub'] as String,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: _P.ink3,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: _P.ink4,
                        ),
                        onTap: () => _selectDestination(item['name'] as String),
                      );
                    },
                  ),
          ),
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
  // ── State (tidak diubah) ─────────────────────────────────────
  int _unreadNotif = 0;
  bool _showCriticalBanner = false;
  String _bannerMessage = '';

  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;

  int _activeNav = 0;

  // ── GPS & Map (tidak diubah) ─────────────────────────────────
  final MapController _mapController = MapController();
  Position? _userPosition;
  final LatLng _medanCenter = const LatLng(3.5952, 98.6722);

  // ── Onboarding (tidak diubah) ────────────────────────────────
  final _keyNotif = GlobalKey();
  final _keyWeather = GlobalKey();
  final _keyQuickRute = GlobalKey();
  final _keyQuickAngkot = GlobalKey();
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

  // ── GPS (tidak diubah) ───────────────────────────────────────
  Future<void> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
      permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() => _userPosition = position);
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15.0,
        );
      }
    }
  }

  // ── Onboarding (tidak diubah) ────────────────────────────────
  Future<void> _maybeShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyDone = prefs.getBool(_kOnboardingDone) ?? false;
    if (alreadyDone) {
      if (mounted) setState(() => _onboardingDone = true);
      return;
    }
    if (mounted)
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && !_onboardingDone) _startOnboarding();
      });
  }

  void _startOnboarding() {
    OnboardingOverlay.show(
      context: context,
      steps: [
        OnboardingStep(
          targetKey: _keyNotif,
          icon: OnboardingIcon.notification,
          title: 'Notifikasi & Peringatan',
          description:
              'Dapatkan alert kemacetan parah dan info penting secara real-time.',
          padding: const EdgeInsets.all(6),
        ),
        OnboardingStep(
          targetKey: _keyWeather,
          icon: OnboardingIcon.weather,
          title: 'Cuaca Real-time Medan',
          description:
              'Pantau suhu, kelembaban, dan angin agar perjalananmu lebih siap.',
          padding: const EdgeInsets.all(8),
        ),
        OnboardingStep(
          targetKey: _keyQuickRute,
          icon: OnboardingIcon.route,
          title: 'Rute Pintar',
          description:
              'Temukan jalur tercepat di Medan dengan rekomendasi berbasis AI.',
          padding: const EdgeInsets.all(6),
        ),
        OnboardingStep(
          targetKey: _keyQuickAngkot,
          icon: OnboardingIcon.angkot,
          title: 'Live Angkot',
          description:
              'Posisi angkot real-time beserta estimasi waktu kedatangan.',
          padding: const EdgeInsets.all(6),
        ),
        OnboardingStep(
          targetKey: _keyTrafficStrip,
          icon: OnboardingIcon.traffic,
          title: 'Prediksi 30 Menit ke Depan',
          description:
              'Cek prakiraan kemacetan 30 menit ke depan untuk waktu terbaik berangkat.',
          padding: const EdgeInsets.all(8),
        ),
      ],
      onFinished: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kOnboardingDone, true);
        if (mounted) setState(() => _onboardingDone = true);
      },
    );
  }

  // ── Notifications (tidak diubah) ─────────────────────────────
  Future<void> _checkNotifications() async {
    try {
      final data = await ApiService().getNotifications();
      setState(() {
        _unreadNotif = data['unread_count'] as int;
        if (_unreadNotif > 0) {
          _showCriticalBanner = true;
          _bannerMessage = data['alerts'][0]['message'] as String;
        }
      });
    } catch (e) {
      debugPrint('Check Notif Failed: $e');
    }
  }

  // ── Fetch Cuaca (tidak diubah) ───────────────────────────────
  Future<void> _fetchWeather() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService().baseUrl}/weather/current'),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _weatherData = decoded;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      debugPrint('Fetch Weather Failed: $e');
      setState(() => _isLoadingWeather = false);
    }
  }

  // ── Buka sheet (tidak diubah) ────────────────────────────────
  void _openDestinationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const _DestinationSheet(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  BUILD — SCROLLABLE CONTENT (desain baru sesuai screenshot)
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────
          SliverToBoxAdapter(child: _buildTopSection()),

          // ── Body Scrollable ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  if (_showCriticalBanner) _buildAlertBanner(),
                  // Aksi Cepat
                  _sectionLabel('AKSI CEPAT'),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                  const SizedBox(height: 20),
                  // Banner Prediksi Kemacetan
                  _buildPredictionBanner(),
                  const SizedBox(height: 24),
                  // Semua Fitur
                  _buildSectionHeader('Semua Fitur', 'Lihat Semua', () {}),
                  const SizedBox(height: 12),
                  _buildFeatureList(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  TOP SECTION — Header putih + Weather Card biru besar
  // ══════════════════════════════════════════════════════════════
  Widget _buildTopSection() {
    return Container(
      color: _P.bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MedFlow',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: _P.b600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getDateString(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: _P.ink3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(key: _keyNotif, child: _notifBtn()),
                ],
              ),
              const SizedBox(height: 20),
              // ── Weather Card biru besar ──────────────────────
              KeyedSubtree(key: _keyWeather, child: _buildWeatherCardBig()),
            ],
          ),
        ),
      ),
    );
  }

  String _getDateString() {
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
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Widget _notifBtn() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationScreen()),
      ),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.notifications_none_outlined,
                color: _P.ink2,
                size: 22,
              ),
            ),
            if (_unreadNotif > 0)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Weather Card Besar persis screenshot ─────────────────────
  Widget _buildWeatherCardBig() {
    if (_isLoadingWeather) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B4EE6), Color(0xFF3B6EF8)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }
    if (_weatherData == null) return const SizedBox.shrink();

    final temp = _weatherData!['temp'] as String;
    final cond = _weatherData!['condition'] as String;
    final loc = _weatherData!['location'] as String;
    final humidity = _weatherData!['humidity'] as String? ?? '–';
    final windSpeed = _weatherData!['wind_speed'] as String? ?? '–';
    final title = _weatherData!['title'] as String? ?? '';
    final tips = _weatherData!['tips'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B4EE6), Color(0xFF3B6EF8), Color(0xFF4B7BFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B4EE6).withOpacity(0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Baris atas: label + ikon cuaca ──────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kiri: label + kondisi + lokasi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CUACA MEDAN',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.60),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cond,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: Colors.white.withOpacity(0.65),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          loc,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.65),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Kanan: ikon animasi + suhu besar
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: _buildWeatherIcon(_weatherData!['icon'] as String),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: temp.replaceAll('°C', ''),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        const TextSpan(
                          text: '°',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),
          // ── Divider ─────────────────────────────────────────
          Divider(color: Colors.white.withOpacity(0.18), height: 1),
          const SizedBox(height: 16),

          // ── Stats: Lembab | Angin ────────────────────────────
          Row(
            children: [
              Expanded(
                child: _weatherStat(
                  Icons.water_drop_outlined,
                  humidity,
                  'Lembab',
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withOpacity(0.18),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: _weatherStat(Icons.air_rounded, windSpeed, 'Angin'),
                ),
              ),
            ],
          ),

          // ── Title & Tips ─────────────────────────────────────
          if (title.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: Colors.white.withOpacity(0.80),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tips
                  .map(
                    (tip) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.22),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tip.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _weatherStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white.withOpacity(0.75)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.60),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherIcon(String iconType) {
    switch (iconType) {
      case 'rainy':
        return const RainyWeatherIcon(size: 72);
      case 'cloudy':
        return const CloudySunIcon(size: 72);
      default:
        return const SunnyIcon(size: 72);
    }
  }

  // ── Alert Banner ──────────────────────────────────────────────
  Widget _buildAlertBanner() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: _showCriticalBanner
          ? Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _bannerMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showCriticalBanner = false),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '✕',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ── Section label ─────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: _P.ink4,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: _P.ink,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            'Lihat Semua',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _P.b600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Quick Actions ─────────────────────────────────────────────
  Widget _buildQuickActions() {
    final items = [
      {
        'icon': Icons.alt_route_rounded,
        'color': const Color(0xFF3B82F6),
        'bg': const Color(0xFFDEEAFD),
        'label': 'Rute\nPintar',
        'key': _keyQuickRute,
        'screen': const RouteRecommendationScreen(),
      },
      {
        'icon': Icons.directions_bus_filled,
        'color': const Color(0xFF10B981),
        'bg': const Color(0xFFCDF4E8),
        'label': 'Pantau\nAngkot',
        'key': _keyQuickAngkot,
        'screen': const AngkotTrackingScreen(),
      },
      {
        'icon': Icons.grid_view_rounded,
        'color': const Color(0xFF22C55E),
        'bg': const Color(0xFFDCFCE7),
        'label': 'Kondisi\nLalu Lintas',
        'key': null,
        'screen': const TrafficHeatmapScreen(),
      },
      {
        'icon': Icons.access_time_rounded,
        'color': const Color(0xFFF97316),
        'bg': const Color(0xFFFEEDD5),
        'label': 'Prediksi\nWaktu',
        'key': null,
        'screen': const TravelTimePredictionScreen(),
      },
    ];

    return Row(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isFirst = index == 0;
        final isLast = index == items.length - 1;
        final Widget child = GestureDetector(
          onTap: () => _push(item['screen'] as Widget),
          child: Container(
            margin: EdgeInsets.only(
              left: isFirst ? 0 : 5,
              right: isLast ? 0 : 5,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: item['bg'] as Color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['label'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _P.ink,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        );

        final key = item['key'];
        return Expanded(
          child: key != null
              ? KeyedSubtree(key: key as Key, child: child)
              : child,
        );
      }),
    );
  }

  // ── Prediction Banner ─────────────────────────────────────────
  Widget _buildPredictionBanner() {
    return GestureDetector(
      key: _keyTrafficStrip,
      onTap: () => _push(const TrafficHeatmapScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: _P.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _P.b100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _P.b100,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _P.b50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.show_chart_rounded,
                color: _P.b600,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prediksi Kemacetan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _P.b600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Data real-time 30 menit ke depan',
                    style: TextStyle(
                      fontSize: 12,
                      color: _P.ink3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _P.b600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Cek →',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Feature List ──────────────────────────────────────────────
  Widget _buildFeatureList() {
    final features = [
      {
        'icon': Icons.access_time_filled_rounded,
        'color': const Color(0xFF3B82F6),
        'bg': const Color(0xFFEFF6FF),
        'title': 'Prediksi Waktu Tempuh',
        'sub': 'Estimasi perjalanan akurat berbasis AI',
        'screen': const TravelTimePredictionScreen(),
      },
      {
        'icon': Icons.grid_view_rounded,
        'color': const Color(0xFF22C55E),
        'bg': const Color(0xFFDCFCE7),
        'title': 'Kondisi Lalu Lintas',
        'sub': 'Heatmap traffic terkini di Medan',
        'screen': const TrafficHeatmapScreen(),
      },
      {
        'icon': Icons.alt_route_rounded,
        'color': const Color(0xFF3B82F6),
        'bg': const Color(0xFFEFF6FF),
        'title': 'Rute Pintar',
        'sub': 'Jalur optimal real-time berbasis AI',
        'screen': const RouteRecommendationScreen(),
      },
      {
        'icon': Icons.directions_bus_filled,
        'color': const Color(0xFFF97316),
        'bg': const Color(0xFFFFF7ED),
        'title': 'Pantau Angkot Live',
        'sub': 'Posisi & ETA angkot secara real-time',
        'screen': const AngkotTrackingScreen(),
      },
    ];

    return Column(
      children: features
          .map(
            (f) => GestureDetector(
              onTap: () => _push(f['screen'] as Widget),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _P.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _P.b50, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: f['bg'] as Color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        f['icon'] as IconData,
                        color: f['color'] as Color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f['title'] as String,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: _P.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            f['sub'] as String,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: _P.ink3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: _P.ink4,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_P.bg.withOpacity(0), _P.bg, _P.bg],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _P.b500.withOpacity(0.14), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _P.b500.withOpacity(0.14),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _nbItem(0, Icons.home_rounded, 'Beranda', onTap: () {}),
              _nbItem(
                1,
                Icons.search_rounded,
                'Rute Pintar',
                onTap: () => _push(const RouteRecommendationScreen()),
              ),
              _nbFab(),
              _nbItem(
                3,
                Icons.show_chart_rounded,
                'Prediksi',
                onTap: () => _push(const TrafficHeatmapScreen()),
              ),
              _nbItem(
                4,
                Icons.lock_outline_rounded,
                'Login',
                onTap: () => _push(const LoginScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nbItem(
    int idx,
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    final on = _activeNav == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _activeNav = idx);
          onTap();
        },
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: on ? _P.b600 : _P.ink4,
                ),
              ),
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
        width: 48,
        height: 48,
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
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.gps_fixed_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  void _push(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
