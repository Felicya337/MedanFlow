import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'otp_verification_screen.dart';

// ─────────────────────────────────────────────
// Palette (same as LandingPage & LoginScreen)
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
//  ANIMATED REGISTER ICON  (clipboard + pen floating)
// ══════════════════════════════════════════════════════════════
class AnimatedRegisterIcon extends StatefulWidget {
  final double size;
  const AnimatedRegisterIcon({super.key, this.size = 90});
  @override
  State<AnimatedRegisterIcon> createState() => _AnimatedRegisterIconState();
}

class _AnimatedRegisterIconState extends State<AnimatedRegisterIcon>
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
      painter: _RegisterPainter(t: _ctrl.value),
    ),
  );
}

class _RegisterPainter extends CustomPainter {
  final double t;
  _RegisterPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final floatY = math.sin(t * math.pi) * 4.0;

    final whitePaint = Paint()..color = Colors.white.withOpacity(0.90);
    final bluePaint = Paint()
      ..color = const Color(0xFF93C5FD).withOpacity(0.85);
    final darkPaint = Paint()
      ..color = const Color(0xFF1E40AF).withOpacity(0.90);

    // ── Clipboard body glow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.14, h * 0.16 + floatY, w * 0.62, h * 0.72),
        const Radius.circular(12),
      ),
      Paint()
        ..color = Colors.white.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // ── Clipboard body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.16, h * 0.18 + floatY, w * 0.58, h * 0.68),
        const Radius.circular(10),
      ),
      whitePaint,
    );

    // ── Clipboard top clip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.36, h * 0.12 + floatY, w * 0.18, h * 0.12),
        const Radius.circular(6),
      ),
      darkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.39, h * 0.15 + floatY, w * 0.12, h * 0.07),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white.withOpacity(0.80),
    );

    // ── Lines (form fields) — animate writing progress
    final writeProgress = t; // 0..1 reverse
    final linePaint = Paint()
      ..color = const Color(0xFF93C5FD).withOpacity(0.70)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    final lineShortPaint = Paint()
      ..color = const Color(0xFF93C5FD).withOpacity(0.45)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    // Line 1 (full)
    canvas.drawLine(
      Offset(w * 0.24, h * 0.36 + floatY),
      Offset(
        w * 0.24 + (w * 0.42) * writeProgress.clamp(0, 1),
        h * 0.36 + floatY,
      ),
      linePaint,
    );
    // Line 2
    final p2 = ((writeProgress - 0.2) / 0.8).clamp(0.0, 1.0);
    canvas.drawLine(
      Offset(w * 0.24, h * 0.47 + floatY),
      Offset(w * 0.24 + (w * 0.42) * p2, h * 0.47 + floatY),
      linePaint,
    );
    // Line 3 (short)
    final p3 = ((writeProgress - 0.4) / 0.6).clamp(0.0, 1.0);
    canvas.drawLine(
      Offset(w * 0.24, h * 0.58 + floatY),
      Offset(w * 0.24 + (w * 0.28) * p3, h * 0.58 + floatY),
      lineShortPaint,
    );
    // Line 4 (short)
    final p4 = ((writeProgress - 0.55) / 0.45).clamp(0.0, 1.0);
    canvas.drawLine(
      Offset(w * 0.24, h * 0.68 + floatY),
      Offset(w * 0.24 + (w * 0.34) * p4, h * 0.68 + floatY),
      lineShortPaint,
    );

    // ── Pen (animated, moves with write progress)
    final penX = w * 0.24 + (w * 0.42) * writeProgress - w * 0.04;
    final penY = h * 0.36 + floatY - h * 0.08;
    _drawPen(canvas, Offset(penX, penY), w * 0.06);
  }

  void _drawPen(Canvas canvas, Offset tip, double size) {
    final penBody = Paint()..color = const Color(0xFF1D4ED8).withOpacity(0.90);
    final penTip = Paint()..color = const Color(0xFF93C5FD).withOpacity(0.95);

    final angle = math.pi / 5;
    final cos = math.cos(angle);
    final sin = math.sin(angle);

    // Pen body rect (rotated)
    final path = Path();
    final bx = tip.dx - cos * size * 0.3;
    final by = tip.dy - sin * size * 0.3;
    path.moveTo(bx - sin * size * 0.25, by + cos * size * 0.25);
    path.lineTo(bx + sin * size * 0.25, by - cos * size * 0.25);
    path.lineTo(
      bx + cos * size * 2.2 + sin * size * 0.25,
      by + sin * size * 2.2 - cos * size * 0.25,
    );
    path.lineTo(
      bx + cos * size * 2.2 - sin * size * 0.25,
      by + sin * size * 2.2 + cos * size * 0.25,
    );
    path.close();
    canvas.drawPath(path, penBody);

    // Tip triangle
    final tipPath = Path();
    tipPath.moveTo(tip.dx, tip.dy);
    tipPath.lineTo(tip.dx - sin * size * 0.22, tip.dy + cos * size * 0.22);
    tipPath.lineTo(
      tip.dx - cos * size * 0.28 - sin * size * 0.22,
      tip.dy - sin * size * 0.28 + cos * size * 0.22,
    );
    tipPath.close();
    canvas.drawPath(tipPath, penTip);
  }

  @override
  bool shouldRepaint(_RegisterPainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════════════
//  DRIVER REGISTER SCREEN
// ══════════════════════════════════════════════════════════════
class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});
  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _plateController = TextEditingController();

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
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  // ── Register Logic (unchanged) ───────────────────────────────
  void _handleRegister() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passController.text.isEmpty ||
        _plateController.text.isEmpty) {
      _showSnackBar('Harap lengkapi semua data pendaftaran.', Colors.orange);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService().registerDriver({
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passController.text,
        'vehicle_plate': _plateController.text,
        'angkot_id': '1',
      });
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(email: _emailController.text),
        ),
      );
    } catch (e) {
      _showSnackBar(e.toString(), Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
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
    return Scaffold(
      backgroundColor: _P.bg,
      body: Stack(
        children: [
          _buildOrbBg(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 24),
                      _buildHeroCard(),
                      const SizedBox(height: 28),
                      _buildFormCard(),
                      const SizedBox(height: 20),
                      _buildLoginLink(),
                    ],
                  ),
                ),
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

  // ── Top Bar ──────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _P.card,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _P.b100, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _P.b500.withOpacity(0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: _P.b600,
            ),
          ),
        ),
        const SizedBox(width: 14),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [_P.b600, Color(0xFF06B6D4)],
          ).createShader(b),
          child: const Text(
            'Medan Flow',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── Hero Card ────────────────────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_P.b600, _P.b800, _P.dark],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _P.b600.withOpacity(0.32),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'MITRA DRIVER MEDAN FLOW',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white70,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Buat Akun\nDriver Baru',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bergabung & bantu mobilitas\nwarga Kota Medan.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const AnimatedRegisterIcon(size: 90),
            ],
          ),
        ],
      ),
    );
  }

  // ── Form Card ────────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _P.b100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _P.b500.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nama Lengkap
          _buildLabel('Nama Lengkap'),
          const SizedBox(height: 8),
          _buildInputField(
            controller: _nameController,
            hint: 'Masukkan nama sesuai KTP',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 18),

          // Email
          _buildLabel('Email Aktif'),
          const SizedBox(height: 8),
          _buildInputField(
            controller: _emailController,
            hint: 'Untuk pengiriman kode OTP',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),

          // Password
          _buildLabel('Password'),
          const SizedBox(height: 8),
          _buildInputField(
            controller: _passController,
            hint: 'Minimal 8 karakter',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
          ),
          const SizedBox(height: 18),

          // Plat
          _buildLabel('Plat Kendaraan (BK)'),
          const SizedBox(height: 8),
          _buildInputField(
            controller: _plateController,
            hint: 'Contoh: BK 1234 ABC',
            icon: Icons.directions_bus_outlined,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 18),

          // OTP info strip
          _buildOtpInfoStrip(),
          const SizedBox(height: 20),

          // Register button
          _buildRegisterButton(),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: _P.ink2,
      letterSpacing: 0.1,
    ),
  );

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _P.b50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.b100, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscureText : false,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
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

  Widget _buildOtpInfoStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _P.b50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.b100, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _P.b100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: _P.b600,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Setelah mendaftar, Anda wajib memverifikasi email melalui kode OTP.',
              style: TextStyle(
                fontSize: 11.5,
                color: _P.ink3,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
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
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleRegister,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: _P.b600,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'DAFTAR SEKARANG',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ── Login Link ───────────────────────────────────────────────
  Widget _buildLoginLink() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: _P.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _P.b100, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _P.b50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.login_rounded, color: _P.b600, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sudah punya akun?',
                    style: TextStyle(
                      fontSize: 12,
                      color: _P.ink3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Login di sini',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: _P.b600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
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
}
