import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────
// Palette (Mewah & Profesional Medan Flow)
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

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  
  bool _isLoading = true;
  List<dynamic> _chartData = [];
  late AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
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

  // ── Logic Pengambilan Data ──────────────────────────────────────────
  Future<void> _fetchAnalytics() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiService().baseUrl}/admin/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint("API Response Status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        setState(() {
          _chartData = decodedData['chart_data'] ?? [];
        });
      } else {
        _showErrorSnackBar("Gagal memuat data (Error: ${response.statusCode})");
      }
    } catch (e) {
      debugPrint('Analytics Catch Error: $e');
      _showErrorSnackBar("Masalah koneksi ke server.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD UTAMA
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      body: Stack(
        children: [
          _buildOrbBg(), 
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Orb Background (Dekorasi Melayang) ─────────────────────────────────
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
                  top: -100 + t * 40,
                  left: -80 + t * 30,
                  child: _orb(350, _P.b400, 0.12),
                ),
                Positioned(
                  top: 250 + t * 40,
                  right: -90 - t * 20,
                  child: _orb(280, const Color(0xFF06B6D4), 0.10),
                ),
                Positioned(
                  bottom: 200 - t * 30,
                  left: 40 + t * 25,
                  child: _orb(200, _P.b300, 0.08),
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

  // ── Header (Glossy Style) ───────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_P.b600, _P.b800, _P.dark],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _P.b600.withOpacity(0.35),
            blurRadius: 25,
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
                    center: const Alignment(0.9, -0.8),
                    radius: 1.2,
                    colors: [Colors.white.withOpacity(0.12), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(
                    width: 38,
                    height: 38,
                    child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Analisis & Laporan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                    ),
                    Text(
                      'Wawasan Mobilitas Kota Medan',
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 14),
                    SizedBox(width: 5),
                    Text('AI', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Body Konten ───────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: _P.b600, strokeWidth: 3),
            const SizedBox(height: 20),
            Text("Menganalisis data...", style: TextStyle(color: _P.ink3, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Visualisasi Kepadatan Mingguan'),
          _buildChartCard(),
          const SizedBox(height: 30),
          _sectionLabel('Insight Mobilitas Medan'),
          _buildInsightCard(
            'Titik Puncak Macet',
            'Jl. Sudirman & Simpang Pos terpantau macet total setiap sore.',
            Icons.trending_up_rounded,
            [const Color(0xFFFEF2F2), const Color(0xFFFECACA)],
            const Color(0xFFDC2626),
          ),
          _buildInsightCard(
            'Efisiensi Armada',
            'Angkot trayek 64 beroperasi 92% lebih efisien minggu ini.',
            Icons.bolt_rounded,
            [_P.b50, _P.b100],
            _P.b600,
          ),
          _buildInsightCard(
            'Laporan Banjir',
            'Tidak ada genangan air yang menghambat rute hari ini.',
            Icons.check_circle_outline_rounded,
            [const Color(0xFFF0FDF4), const Color(0xFFBBF7D0)],
            const Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _P.ink2, letterSpacing: 1.1),
      ),
    );
  }

  // ── Chart Card (FIXED OVERFLOW LOGIC) ──────────────────────────────────
  Widget _buildChartCard() {
    if (_chartData.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Text("Data statistik tidak ditemukan.", style: TextStyle(color: _P.ink4)),
      );
    }

    final maxVal = _chartData.map((d) => (d['value'] as num).toDouble()).reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: _P.b500.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Indeks Kemacetan (%)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _P.ink2)),
              const Icon(Icons.more_horiz, color: _P.ink4),
            ],
          ),
          const SizedBox(height: 25),
          // PERBAIKAN: Meningkatkan tinggi Box dari 180 ke 200 agar tidak overflow
          SizedBox(
            height: 200, 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _chartData.map<Widget>((d) {
                final val = (d['value'] as num).toDouble();
                // PERBAIKAN LOGIKA TINGGI: (val / maxVal) * 120 agar sisa ruang untuk teks cukup
                final barH = (val / (maxVal > 0 ? maxVal : 1)) * 120.0;
                final bool isHigh = val > 70;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${val.toInt()}%', 
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isHigh ? Colors.red : _P.b600)),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(seconds: 1),
                      width: 28, // Sedikit dipersempit untuk spasi visual
                      height: barH.clamp(12, 140),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isHigh ? [const Color(0xFFF87171), Colors.red] : [_P.b300, _P.b600],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(d['day'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _P.ink2)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Insight Card ───────────────────────────────────────────────────────
  Widget _buildInsightCard(String title, String desc, IconData icon, List<Color> bg, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _P.b100, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: bg, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _P.ink)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 12, color: _P.ink3, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}