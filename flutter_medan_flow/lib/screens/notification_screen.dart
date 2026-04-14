import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────
// Palette (sama dengan LandingPage)
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

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _alerts = [];
  bool _isLoading = true;

  late AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
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

  Future<void> _loadNotifications() async {
    try {
      final data = await _apiService.getNotifications();
      setState(() {
        _alerts = data['alerts'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Notif Error: $e");
      setState(() => _isLoading = false);
    }
  }

  // ── Orb background (identik dengan LandingPage) ──────────────
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
                  child: _orb(260, _P.b400, 0.14),
                ),
                Positioned(
                  top: 200 + t * 28,
                  right: -70 - t * 18,
                  child: _orb(200, const Color(0xFF06B6D4), 0.12),
                ),
                Positioned(
                  bottom: 200 - t * 22,
                  left: 20 + t * 18,
                  child: _orb(160, _P.b300, 0.11),
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

  // ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildOrbBg(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading
                      ? _buildLoading()
                      : _alerts.isEmpty
                      ? _buildEmptyState()
                      : _buildList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _P.b600,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [_P.b600, Color(0xFF06B6D4)],
                  ).createShader(b),
                  child: const Text(
                    'Notifikasi',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const Text(
                  'Peringatan & Info Terkini',
                  style: TextStyle(
                    fontSize: 12,
                    color: _P.ink3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Refresh button
          GestureDetector(
            onTap: () {
              setState(() => _isLoading = true);
              _loadNotifications();
            },
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
              child: const Icon(
                Icons.refresh_rounded,
                color: _P.b600,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading ──────────────────────────────────────────────────
  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: _P.b600, strokeWidth: 2.5),
    );
  }

  // ── Empty State ──────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _P.b50,
              shape: BoxShape.circle,
              border: Border.all(color: _P.b100, width: 2),
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              color: _P.b300,
              size: 40,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Semua Aman!',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _P.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tidak ada notifikasi baru saat ini.',
            style: TextStyle(
              fontSize: 13,
              color: _P.ink3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── List ─────────────────────────────────────────────────────
  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      physics: const BouncingScrollPhysics(),
      itemCount: _alerts.length,
      itemBuilder: (context, index) => _buildNotificationCard(_alerts[index]),
    );
  }

  // ── Notification Card ─────────────────────────────────────────
  Widget _buildNotificationCard(dynamic item) {
    // Tentukan warna & ikon berdasarkan tipe
    final bool isCritical = item['is_critical'] == true;

    IconData icon;
    List<Color> iconBg;
    Color iconColor;

    if (item['type'] == 'weather') {
      icon = Icons.cloudy_snowing;
      iconBg = [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)];
      iconColor = const Color(0xFF0EA5E9);
    } else if (item['type'] == 'traffic') {
      icon = Icons.traffic_rounded;
      iconBg = isCritical
          ? [const Color(0xFFFEF2F2), const Color(0xFFFECACA)]
          : [_P.b50, _P.b100];
      iconColor = isCritical ? Colors.red : _P.b500;
    } else {
      icon = Icons.lightbulb_outline_rounded;
      iconBg = [const Color(0xFFFFF7ED), const Color(0xFFFED7AA)];
      iconColor = const Color(0xFFEA580C);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCritical ? const Color(0xFFFECACA) : _P.b100,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isCritical
                ? Colors.red.withOpacity(0.06)
                : _P.b500.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ikon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: iconBg,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 13),
          // Konten
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['title'] as String,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _P.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item['time'] as String,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: _P.ink4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  item['message'] as String,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _P.ink3,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                // Badge kritis
                if (isCritical) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFECACA),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 11,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Perhatian Penting',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
