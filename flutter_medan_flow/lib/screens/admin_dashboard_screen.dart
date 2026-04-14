import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'driver_management_screen.dart';
import 'traffic_heatmap_screen.dart';
import 'angkot_tracking_screen.dart';
import 'admin_analytics_screen.dart';
import 'driver_approval_screen.dart';
import 'landing_page.dart';

// ─────────────────────────────────────────────
// Palette (same as LandingPage & other screens)
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

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  // ── Data (unchanged) ─────────────────────────────────────────
  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;

  // ── Animation ────────────────────────────────────────────────
  late AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    super.dispose();
  }

  // ── Logic (unchanged) ────────────────────────────────────────
  Future<void> _fetchWeather() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService().baseUrl}/weather/current'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _weatherData = jsonDecode(response.body);
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      debugPrint('Gagal muat cuaca admin: $e');
      setState(() => _isLoadingWeather = false);
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _P.card,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFDC2626),
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Logout Admin?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: _P.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Apakah Anda ingin keluar dari Pusat Kendali Dishub?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: _P.ink3,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _P.b50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _P.b100, width: 1.5),
                        ),
                        child: const Center(
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _P.b600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LandingPage(),
                          ),
                          (route) => false,
                        );
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'Keluar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _push(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  // ════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      body: Stack(
        children: [
          _buildOrbBg(),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildWeatherCard()),
                SliverToBoxAdapter(child: _sectionLabel('Status Operasional')),
                SliverToBoxAdapter(child: _buildQuickStats()),
                SliverToBoxAdapter(child: _sectionLabel('Modul Manajemen')),
                SliverToBoxAdapter(child: _buildModuleList()),
                const SliverToBoxAdapter(child: SizedBox(height: 60)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Orb Background ───────────────────────────────────────────
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                  'Pusat Kendali',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const Text(
                'DISHUB MEDAN — Admin Panel',
                style: TextStyle(
                  fontSize: 11.5,
                  color: _P.ink3,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          // Action buttons
          Row(
            children: [
              _headerBtn(Icons.refresh_rounded, onTap: _fetchWeather),
              const SizedBox(width: 8),
              _headerBtn(
                Icons.logout_rounded,
                onTap: _showLogoutConfirmation,
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerBtn(
    IconData icon, {
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDestructive ? const Color(0xFFFEF2F2) : _P.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDestructive ? const Color(0xFFFECACA) : _P.b100,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDestructive ? const Color(0xFFDC2626) : _P.b500)
                  .withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isDestructive ? const Color(0xFFDC2626) : _P.b600,
          size: 20,
        ),
      ),
    );
  }

  // ── Weather Card ─────────────────────────────────────────────
  Widget _buildWeatherCard() {
    if (_isLoadingWeather) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        height: 100,
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
              color: _P.b600.withOpacity(0.30),
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

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
          // Radial gloss
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
              // Left: label + condition + location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CUACA LAPANGAN',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white54,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _weatherData?['condition'] ?? '—',
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
                      children: const [
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.white54,
                          size: 11,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'Medan Kota',
                          style: TextStyle(
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
              // Right: icon + temp
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloudy_snowing,
                    color: Colors.white,
                    size: 38,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _weatherData?['temp'] ?? '—',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section Label ────────────────────────────────────────────
  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _P.ink2,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Quick Stats ──────────────────────────────────────────────
  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          _statCard(
            '142',
            'Angkot Online',
            Icons.directions_bus_rounded,
            [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
            const Color(0xFF0EA5E9),
          ),
          const SizedBox(width: 12),
          _statCard('Low', 'Index Macet', Icons.speed_rounded, [
            const Color(0xFFF0FDF4),
            const Color(0xFFDCFCE7),
          ], const Color(0xFF16A34A)),
        ],
      ),
    );
  }

  Widget _statCard(
    String value,
    String label,
    IconData icon,
    List<Color> gradient,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _P.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: _P.ink3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Module List ──────────────────────────────────────────────
  Widget _buildModuleList() {
    final modules = [
      _Mod(
        'Kelola Driver & Armada',
        'Data personil dan unit angkot.',
        Icons.people_alt_rounded,
        [_P.b50, _P.b100],
        _P.b500,
        const DriverManagementScreen(),
        null,
      ),
      _Mod(
        'Persetujuan Akun',
        'Aktivasi pendaftaran driver baru.',
        Icons.how_to_reg_rounded,
        [const Color(0xFFFFF7ED), const Color(0xFFFED7AA)],
        const Color(0xFFEA580C),
        const DriverApprovalScreen(),
        'Pending',
      ),
      _Mod(
        'Monitoring Real-time',
        'Pantau pergerakan angkot aktif.',
        Icons.gps_fixed_rounded,
        [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
        const Color(0xFF0EA5E9),
        const AngkotTrackingScreen(),
        'Live',
      ),
      _Mod(
        'Peta Panas (Heatmap)',
        'Analisis titik kemacetan.',
        Icons.whatshot_rounded,
        [const Color(0xFFFFF7ED), const Color(0xFFFED7AA)],
        const Color(0xFFEA580C),
        const TrafficHeatmapScreen(),
        null,
      ),
      _Mod(
        'Analisis Data AI',
        'Laporan tren mingguan.',
        Icons.analytics_rounded,
        [const Color(0xFFF5F3FF), const Color(0xFFEDE9FE)],
        const Color(0xFF7C3AED),
        const AdminAnalyticsScreen(),
        null,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: modules
            .map(
              (m) => GestureDetector(
                onTap: () => _push(m.target),
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
                      // Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: m.iconBg,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(m.icon, color: m.iconColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _P.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.subtitle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: _P.ink3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge + chevron
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (m.badge != null) ...[
                            _moduleBadge(m.badge!, m.iconColor),
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

  Widget _moduleBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────
class _Mod {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> iconBg;
  final Color iconColor;
  final Widget target;
  final String? badge;
  const _Mod(
    this.title,
    this.subtitle,
    this.icon,
    this.iconBg,
    this.iconColor,
    this.target,
    this.badge,
  );
}
