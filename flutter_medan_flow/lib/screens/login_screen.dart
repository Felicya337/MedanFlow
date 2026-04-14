import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'driver_home_screen.dart';
import 'admin_dashboard_screen.dart';
import 'driver_register_screen.dart';

// ─────────────────────────────────────────────
// Palette (same as all other screens)
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
//  ANIMATED BUS ICON  (unchanged)
// ══════════════════════════════════════════════════════════════
class AnimatedBusIcon extends StatefulWidget {
  final double size;
  const AnimatedBusIcon({super.key, this.size = 80});
  @override
  State<AnimatedBusIcon> createState() => _AnimatedBusIconState();
}

class _AnimatedBusIconState extends State<AnimatedBusIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
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
      painter: _BusPainter(t: _ctrl.value),
    ),
  );
}

class _BusPainter extends CustomPainter {
  final double t;
  _BusPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final floatY = math.sin(t * math.pi) * 4.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.22 + floatY, w * 0.90, h * 0.52),
        const Radius.circular(14),
      ),
      Paint()
        ..color = Colors.white.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.24 + floatY, w * 0.84, h * 0.48),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader =
            LinearGradient(
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.78),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(
              Rect.fromLTWH(w * 0.08, h * 0.24 + floatY, w * 0.84, h * 0.48),
            ),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.24 + floatY, w * 0.84, h * 0.10),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFF60A5FA).withOpacity(0.70),
    );

    final winPaint = Paint()..color = const Color(0xFF93C5FD).withOpacity(0.85);
    final winY = h * 0.32 + floatY;
    final winH = h * 0.16;
    for (int i = 0; i < 3; i++) {
      final winX = w * (0.13 + i * 0.27);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(winX, winY, w * 0.20, winH),
          const Radius.circular(5),
        ),
        winPaint,
      );
    }

    canvas.drawLine(
      Offset(w * 0.20, h * 0.74 + floatY),
      Offset(w * 0.80, h * 0.74 + floatY),
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..strokeWidth = 1.5,
    );

    _drawWheel(canvas, Offset(w * 0.24, h * 0.77 + floatY), w * 0.11, t);
    _drawWheel(canvas, Offset(w * 0.76, h * 0.77 + floatY), w * 0.11, t);

    final lineOpacity = (math.sin(t * math.pi * 2) * 0.5 + 0.5) * 0.60;
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(lineOpacity)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * -0.04, h * 0.44 + floatY),
      Offset(w * 0.06, h * 0.44 + floatY),
      linePaint,
    );
    canvas.drawLine(
      Offset(w * -0.06, h * 0.50 + floatY),
      Offset(w * 0.07, h * 0.50 + floatY),
      linePaint..color = Colors.white.withOpacity(lineOpacity * 0.65),
    );
    canvas.drawLine(
      Offset(w * -0.03, h * 0.56 + floatY),
      Offset(w * 0.05, h * 0.56 + floatY),
      linePaint..color = Colors.white.withOpacity(lineOpacity * 0.40),
    );
  }

  void _drawWheel(Canvas canvas, Offset center, double r, double t) {
    canvas.drawCircle(
      center,
      r,
      Paint()..color = const Color(0xFF1E40AF).withOpacity(0.90),
    );
    canvas.drawCircle(
      center,
      r * 0.45,
      Paint()..color = Colors.white.withOpacity(0.90),
    );
    final spokePaint = Paint()
      ..color = const Color(0xFF1D4ED8).withOpacity(0.85)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (int s = 0; s < 6; s++) {
      final angle = (s / 6) * math.pi * 2 + t * math.pi * 4;
      canvas.drawLine(
        center.translate(
          math.cos(angle) * r * 0.45,
          math.sin(angle) * r * 0.45,
        ),
        center.translate(
          math.cos(angle) * r * 0.88,
          math.sin(angle) * r * 0.88,
        ),
        spokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BusPainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════════════
//  LOGIN SCREEN  — new full-screen split layout
// ══════════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _obscureText = true;

  // ── Animations ───────────────────────────────────────────────
  late AnimationController _orbCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _entryCtrl.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  // ── Login Logic (unchanged) ──────────────────────────────────
  void _login() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      _snack('Harap isi email dan password Anda.', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.login(
        _emailController.text,
        _passController.text,
      );
      if (!mounted) return;
      final roleId = res['user']['role_id'] as int;
      if (roleId == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else if (roleId == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
        );
      } else {
        _snack('Login Berhasil.');
      }
    } catch (_) {
      _snack('Gagal Masuk: Email atau password salah.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: isError ? const Color(0xFFB91C1C) : _P.b600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _P.bg,
      body: Stack(
        children: [
          // ── Full orb bg
          _buildOrbBg(),

          // ── Top hero panel  (≈40% height)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenH * 0.42,
            child: _buildHeroPanel(),
          ),

          // ── Scrollable bottom sheet that slides up over hero
          Positioned(
            top: screenH * 0.33,
            left: 0,
            right: 0,
            bottom: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: _buildBottomSheet(),
              ),
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
                  top: 200 + t * 28,
                  right: -70 - t * 18,
                  child: _orb(220, const Color(0xFF06B6D4), 0.14),
                ),
                Positioned(
                  bottom: 120 - t * 22,
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

  // ── Hero Panel ───────────────────────────────────────────────
  Widget _buildHeroPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_P.b600, _P.b800, _P.dark],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Radial gloss
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.80, -0.70),
                  radius: 1.2,
                  colors: [Colors.white.withOpacity(0.09), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          width: 38,
                          height: 38,
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
                      // Portal badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'DRIVER & ADMIN PORTAL',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Title + bus icon row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (b) => LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0.75),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(b),
                              child: const Text(
                                'Selamat\nDatang\nKembali',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.10,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4ADE80),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Medan Flow — Sistem Transportasi Pintar',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.white.withOpacity(0.60),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const AnimatedBusIcon(size: 100),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Sheet ─────────────────────────────────────────────
  Widget _buildBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: _P.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _P.b200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Section title
            const Text(
              'Masuk ke Akun',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _P.ink,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Gunakan email dan password terdaftar.',
              style: TextStyle(
                fontSize: 13,
                color: _P.ink3,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 24),

            // ── Email field
            _fieldLabel('Email Address'),
            const SizedBox(height: 8),
            _inputField(
              controller: _emailController,
              hint: 'contoh@mail.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 16),

            // ── Password field
            _fieldLabel('Password'),
            const SizedBox(height: 8),
            _inputField(
              controller: _passController,
              hint: 'Masukkan password Anda',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
            ),

            // ── Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Lupa Password?',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: _P.b600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // ── Login button
            _loginButton(),

            const SizedBox(height: 28),

            // ── Divider
            Row(
              children: [
                Expanded(child: Container(height: 1, color: _P.b100)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'atau',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _P.ink4,
                    ),
                  ),
                ),
                Expanded(child: Container(height: 1, color: _P.b100)),
              ],
            ),

            const SizedBox(height: 20),

            // ── Footer cards row  (register + admin)
            Row(
              children: [
                Expanded(
                  child: _footerCard(
                    icon: Icons.person_add_outlined,
                    iconBg: _P.b50,
                    iconColor: _P.b600,
                    label: 'Daftar Driver',
                    sublabel: 'Buat akun baru',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DriverRegisterScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _footerCard(
                    icon: Icons.admin_panel_settings_outlined,
                    iconBg: const Color(0xFFF0F9FF),
                    iconColor: const Color(0xFF0EA5E9),
                    label: 'Admin IT',
                    sublabel: 'Hubungi DISHUB',
                    onTap: () {},
                    accentColor: const Color(0xFF0EA5E9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Field Label ──────────────────────────────────────────────
  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: _P.ink2,
      letterSpacing: 0.1,
    ),
  );

  // ── Input Field ──────────────────────────────────────────────
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.b100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _P.b500.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscureText : false,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _P.ink,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 13.5,
            color: _P.ink4,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: _P.b400, size: 20),
          suffixIcon: isPassword
              ? GestureDetector(
                  onTap: () => setState(() => _obscureText = !_obscureText),
                  child: Icon(
                    _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _P.ink4,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 4,
          ),
        ),
      ),
    );
  }

  // ── Login Button ─────────────────────────────────────────────
  Widget _loginButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 54,
      decoration: BoxDecoration(
        gradient: _isLoading
            ? null
            : const LinearGradient(
                colors: [_P.b500, _P.b700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: _isLoading ? _P.b200 : null,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _isLoading
            ? []
            : [
                BoxShadow(
                  color: _P.b600.withOpacity(0.38),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _login,
          borderRadius: BorderRadius.circular(18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isLoading) ...[
                const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
              ],
              _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: _P.b600,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'MASUK KE DASHBOARD',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Footer Card ──────────────────────────────────────────────
  Widget _footerCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
    Color accentColor = _P.b600,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _P.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _P.b100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _P.b500.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: const TextStyle(
                fontSize: 11,
                color: _P.ink3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
