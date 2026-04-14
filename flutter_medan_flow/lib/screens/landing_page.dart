import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
//  ANIMATED WEATHER ICONS
// ══════════════════════════════════════════════════════════════

class RainyWeatherIcon extends StatefulWidget {
  final double size;
  const RainyWeatherIcon({super.key, this.size = 64});
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
    final path = Path();
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
  const CloudySunIcon({super.key, this.size = 64});
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
    final path = Path();
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
  const SunnyIcon({super.key, this.size = 64});
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

  String? _weatherTitle;
  List<String> _weatherTips = [];

  int _activeNav = 0;
  late AnimationController _orbCtrl;

  // ── GlobalKeys untuk onboarding ──────────────────────────────
  final _keyNotif = GlobalKey();
  final _keyWeather = GlobalKey();
  final _keyQuickRute = GlobalKey();
  final _keyQuickAngkot = GlobalKey();
  final _keyTrafficStrip = GlobalKey();

  // ── Key SharedPreferences untuk flag onboarding ──────────────
  static const _kOnboardingDone = 'onboarding_done';

  bool _onboardingDone = false;

  @override
  void initState() {
    super.initState();
    _checkNotifications();
    _fetchWeather();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cek SharedPreferences dulu sebelum memutuskan tampilkan onboarding
      _maybeShowOnboarding();
    });
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    super.dispose();
  }

  // ── Cek apakah onboarding perlu ditampilkan ──────────────────
  /// Membaca flag dari SharedPreferences.
  /// Jika belum pernah selesai onboarding → tampilkan.
  /// Jika sudah → langsung skip.
  Future<void> _maybeShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyDone = prefs.getBool(_kOnboardingDone) ?? false;

    if (alreadyDone) {
      // Onboarding sudah pernah selesai, tidak perlu ditampilkan lagi
      if (mounted) setState(() => _onboardingDone = true);
      return;
    }

    // Belum pernah selesai, tampilkan setelah delay kecil
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && !_onboardingDone) _startOnboarding();
      });
    }
  }

  // ── Onboarding ───────────────────────────────────────────────
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
        // Simpan flag ke SharedPreferences agar tidak muncul lagi
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
        if (_unreadNotif > 0) {
          _showCriticalBanner = true;
          _bannerMessage = data['alerts'][0]['message'] as String;
        }
      });
    } catch (e) {
      debugPrint('Check Notif Failed: $e');
    }
  }

  // ── Fetch cuaca ──────────────────────────────────────────────
  Future<void> _fetchWeather() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService().baseUrl}/weather/current'),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _weatherData = decoded;
          _weatherTitle = decoded['title'] as String?;
          final rawTips = decoded['tips'];
          _weatherTips = rawTips is List
              ? rawTips.map((e) => e.toString()).toList()
              : [];
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      debugPrint('Fetch Weather Failed: $e');
      setState(() => _isLoadingWeather = false);
    }
  }

  // ════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      extendBody: true,
      body: Stack(
        children: [
          _buildOrbBg(),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                if (_showCriticalBanner)
                  SliverToBoxAdapter(child: _buildAlertBanner()),
                SliverToBoxAdapter(child: _buildWeatherCard()),
                SliverToBoxAdapter(child: _sectionLabel('Aksi Cepat')),
                SliverToBoxAdapter(child: _buildQuickActions()),
                SliverToBoxAdapter(child: _buildTrafficStrip()),
                SliverToBoxAdapter(
                  child: _sectionLabel('Semua Fitur', trailing: 'Lihat Semua'),
                ),
                SliverToBoxAdapter(child: _buildFeatureList()),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Orb BG ───────────────────────────────────────────────────
  Widget _buildOrbBg() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _orbCtrl,
          builder: (_, __) {
            final t = _orbCtrl.value;
            return Stack(
              children: [
                Positioned(
                  top: -80 + t * 38,
                  left: -60 + t * 28,
                  child: _orb(300, _P.b400, 0.16),
                ),
                Positioned(
                  top: 180 + t * 28,
                  right: -70 - t * 18,
                  child: _orb(220, const Color(0xFF06B6D4), 0.14),
                ),
                Positioned(
                  bottom: 280 - t * 22,
                  left: 20 + t * 18,
                  child: _orb(180, _P.b300, 0.13),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _orb(double size, Color color, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withOpacity(opacity), Colors.transparent],
      ),
    ),
  );

  // ── Header ───────────────────────────────────────────────────
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
    final dateStr =
        '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [_P.b600, Color(0xFF06B6D4)],
                ).createShader(b),
                child: const Text(
                  'MedFlow',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: _P.ink3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(key: _keyNotif, child: _notifBtn()),
        ],
      ),
    );
  }

  Widget _notifBtn() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationScreen()),
      ),
      child: Container(
        width: 42,
        height: 42,
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
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.notifications_none_outlined,
                color: _P.b600,
                size: 20,
              ),
            ),
            if (_unreadNotif > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 9,
                  height: 9,
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

  // ── Alert Banner ─────────────────────────────────────────────
  Widget _buildAlertBanner() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: _showCriticalBanner
          ? Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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

  // ── Weather Card ──────────────────────────────────────────────
  Widget _buildWeatherCard() {
    return KeyedSubtree(key: _keyWeather, child: _buildWeatherCardContent());
  }

  Widget _buildWeatherCardContent() {
    if (_isLoadingWeather) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_P.b600, _P.b800, _P.dark],
            stops: [0, 0.55, 1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _P.b600.withOpacity(0.32),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    if (_weatherData == null) return const SizedBox.shrink();

    final iconType = _weatherData!['icon'] as String;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
            blurRadius: 28,
            offset: const Offset(0, 8),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CUACA MEDAN',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white54,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _weatherData!['condition'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Colors.white54,
                                size: 11,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _weatherData!['location'] as String,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.white54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: _buildAnimatedWeatherIcon(iconType),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: (_weatherData!['temp'] as String)
                                    .replaceAll('°C', ''),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              const TextSpan(
                                text: '°',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Container(height: 1, color: Colors.white.withOpacity(0.12)),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      _wxStat(
                        Icons.water_drop_outlined,
                        _weatherData!['humidity'] as String,
                        'Lembab',
                      ),
                      Container(
                        width: 1,
                        height: 26,
                        color: Colors.white.withOpacity(0.13),
                      ),
                      _wxStat(
                        Icons.air_rounded,
                        _weatherData!['wind_speed'] as String,
                        'Angin',
                      ),
                    ],
                  ),
                ),

                if (_weatherTitle != null || _weatherTips.isNotEmpty)
                  _buildWeatherInfoBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfoBox() {
    final hasTitle = _weatherTitle != null && _weatherTitle!.isNotEmpty;
    final hasTips = _weatherTips.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTitle)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white70,
                    size: 12,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _weatherTitle!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          if (hasTitle && hasTips)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Container(
                height: 1,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          if (hasTips)
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: _weatherTips.map(_buildTipChip).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTipChip(String tip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.70),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            tip,
            style: const TextStyle(
              fontSize: 10.5,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedWeatherIcon(String iconType) {
    switch (iconType) {
      case 'rainy':
        return const RainyWeatherIcon(size: 64);
      case 'cloudy':
        return const CloudySunIcon(size: 64);
      default:
        return const SunnyIcon(size: 64);
    }
  }

  Widget _wxStat(IconData icon, String value, String label) => Expanded(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white54, size: 13),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 9.5, color: Colors.white54),
            ),
          ],
        ),
      ],
    ),
  );

  // ── Section Label ────────────────────────────────────────────
  Widget _sectionLabel(String label, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _P.ink2,
              letterSpacing: 0.5,
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: const TextStyle(
                fontSize: 12.5,
                color: _P.b600,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  // ── Quick Actions ────────────────────────────────────────────
  Widget _buildQuickActions() {
    final items = [
      _QA(
        'Rute\nPintar',
        [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
        const Icon(Icons.alt_route_rounded, color: _P.b400, size: 26),
        () => _push(const RouteRecommendationScreen()),
        _keyQuickRute,
      ),
      _QA(
        'Pantau\nAngkot',
        [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
        const Icon(
          Icons.directions_bus_rounded,
          color: Color(0xFF0EA5E9),
          size: 26,
        ),
        () => _push(const AngkotTrackingScreen()),
        _keyQuickAngkot,
      ),
      _QA(
        'Kondisi\nLalu Lintas',
        [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
        const Icon(Icons.grid_view_rounded, color: Color(0xFF16A34A), size: 26),
        () => _push(const TrafficHeatmapScreen()),
        GlobalKey(),
      ),
      _QA(
        'Prediksi\nWaktu',
        [const Color(0xFFFFF7ED), const Color(0xFFFED7AA)],
        const Icon(Icons.schedule_rounded, color: Color(0xFFEA580C), size: 26),
        () => _push(const TravelTimePredictionScreen()),
        GlobalKey(),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: List.generate(items.length, (i) {
          final a = items[i];
          return Expanded(
            child: GestureDetector(
              onTap: a.onTap,
              child: Container(
                key: a.targetKey,
                margin: EdgeInsets.only(right: i < items.length - 1 ? 10 : 0),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _P.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _P.b100, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _P.b500.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: a.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(child: a.iconWidget),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      a.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _P.ink,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Traffic Strip ────────────────────────────────────────────
  Widget _buildTrafficStrip() {
    return GestureDetector(
      onTap: () => _push(const TrafficHeatmapScreen()),
      child: Container(
        key: _keyTrafficStrip,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _P.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _P.b100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _P.b500.withOpacity(0.05),
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
                color: _P.b50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(Icons.show_chart_rounded, color: _P.b600, size: 22),
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prediksi Kemacetan',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: _P.b700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Data real-time 30 menit ke depan',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _P.ink3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _P.b600,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Cek →',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Feature List ─────────────────────────────────────────────
  Widget _buildFeatureList() {
    final list = [
      _Feat(
        Icons.analytics_outlined,
        [_P.b50, _P.b100],
        _P.b500,
        'Prediksi Waktu Tempuh',
        'Estimasi perjalanan akurat berbasis AI',
        null,
        null,
        null,
        () => _push(const TravelTimePredictionScreen()),
      ),
      _Feat(
        Icons.grid_view_rounded,
        [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
        const Color(0xFF0EA5E9),
        'Kondisi Lalu Lintas',
        'Visualisasi kemacetan jalanan Medan',
        null,
        null,
        null,
        () => _push(const TrafficHeatmapScreen()),
      ),
      _Feat(
        Icons.directions_bus_outlined,
        [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
        const Color(0xFF16A34A),
        'Lokasi Angkot Real-time',
        'Pantau armada & estimasi kedatangan',
        'Live',
        const Color(0xFFDCFCE7),
        const Color(0xFF15803D),
        () => _push(const AngkotTrackingScreen()),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      child: Column(
        children: list
            .map(
              (f) => GestureDetector(
                onTap: f.onTap,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 11),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: _P.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _P.b100, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _P.b500.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: f.iconBg,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(f.icon, color: f.iconColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _P.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              f.subtitle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: _P.ink3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (f.badge != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: f.badgeBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                f.badge!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: f.badgeFg,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
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
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Bottom Nav ───────────────────────────────────────────────
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
            color: Colors.white.withOpacity(0.92),
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

// ── Data model helpers ────────────────────────────────────────
class _QA {
  final String label;
  final List<Color> gradient;
  final Widget iconWidget;
  final VoidCallback onTap;
  final GlobalKey targetKey;
  const _QA(
    this.label,
    this.gradient,
    this.iconWidget,
    this.onTap,
    this.targetKey,
  );
}

class _Feat {
  final IconData icon;
  final List<Color> iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeBg;
  final Color? badgeFg;
  final VoidCallback onTap;
  const _Feat(
    this.icon,
    this.iconBg,
    this.iconColor,
    this.title,
    this.subtitle,
    this.badge,
    this.badgeBg,
    this.badgeFg,
    this.onTap,
  );
}
