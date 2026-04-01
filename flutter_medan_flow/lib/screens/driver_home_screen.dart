import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/tracking_provider.dart';
import '../services/api_service.dart';
import 'landing_page.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  Map<String, dynamic>? _insights;
  bool _loadingInsight = true;
  String _errorMessage = "";
  final ApiService _apiService = ApiService();

  // Warna Tema khusus Driver (Deep Blue/Indigo)
  final Color primaryColor = const Color(0xFF1A237E); 
  final Color accentColor = const Color(0xFF3949AB);
  final Color scaffoldBg = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _fetchInsights();
  }

  Future<void> _fetchInsights() async {
    setState(() {
      _loadingInsight = true;
      _errorMessage = "";
    });
    try {
      final response = await http
          .get(Uri.parse("${ApiService().baseUrl}/driver/insights"))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        setState(() {
          _insights = jsonDecode(response.body);
          _loadingInsight = false;
        });
      } else {
        setState(() {
          _errorMessage = "Gagal memuat data (Error ${response.statusCode})";
          _loadingInsight = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Tidak bisa terhubung ke server.";
        _loadingInsight = false;
      });
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar dari akun Driver?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("BATAL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LandingPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("YA, KELUAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. APP BAR DENGAN GRADASI INDIGO
          SliverAppBar(
            expandedHeight: 100.0,
            floating: false,
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: const Text(
                "MEDAN FLOW - DRIVER",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, accentColor],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchInsights),
              IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.white), onPressed: _showLogoutConfirmation),
              const SizedBox(width: 10),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. ZONA GRADASI TRANSISI (Header Fading)
                Stack(
                  children: [
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentColor, scaffoldBg],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    _buildStatusHeader(),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Kondisi Operasional",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                      ),
                      const SizedBox(height: 15),

                      if (_loadingInsight)
                        Center(child: Padding(padding: const EdgeInsets.all(40), child: CircularProgressIndicator(color: primaryColor)))
                      else if (_errorMessage.isNotEmpty)
                        _buildErrorSection()
                      else
                        _buildInsightSection(),

                      const SizedBox(height: 30),
                      _buildTrackingButton(context),
                      const SizedBox(height: 25),
                      _buildVehicleInfo(),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Consumer<TrackingProvider>(
        builder: (context, tracking, child) {
          return Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Icon(Icons.person, color: primaryColor, size: 30),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Bang Ucok Sopir", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: tracking.isTracking ? Colors.green : Colors.orange),
                      const SizedBox(width: 6),
                      Text(
                        tracking.isTracking ? "SEDANG BERTUGAS" : "SEDANG ISTIRAHAT",
                        style: TextStyle(
                          color: tracking.isTracking ? Colors.green : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 13)),
          TextButton(onPressed: _fetchInsights, child: const Text("Coba Lagi")),
        ],
      ),
    );
  }

  Widget _buildInsightSection() {
    if (_insights == null) return const SizedBox.shrink();
    
    IconData weatherIcon = Icons.wb_sunny_outlined;
    Color weatherColor = Colors.orange;
    String condition = _insights!['weather']['condition'].toString().toLowerCase();
    if (condition.contains('hujan')) {
      weatherIcon = Icons.cloudy_snowing;
      weatherColor = Colors.blue;
    }

    return Column(
      children: [
        Row(
          children: [
            _insightTile("Cuaca Medan", _insights!['weather']['temp'] ?? "--", _insights!['weather']['condition'], weatherIcon, weatherColor),
            const SizedBox(width: 15),
            _insightTile("Lalu Lintas", _insights!['traffic']['level'].toString().toUpperCase(), _insights!['traffic']['description'], Icons.traffic_outlined, Colors.deepOrange),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _insights!['is_good_to_work'] ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _insights!['is_good_to_work'] ? Colors.green.shade200 : Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(
                _insights!['is_good_to_work'] ? Icons.check_circle_rounded : Icons.info_rounded,
                color: _insights!['is_good_to_work'] ? Colors.green.shade700 : Colors.red.shade700,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _insights!['recommendation'],
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _insightTile(String label, String value, String sub, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(sub, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingButton(BuildContext context) {
    return Consumer<TrackingProvider>(
      builder: (context, tracking, child) {
        bool active = tracking.isTracking;
        return GestureDetector(
          onTap: () => tracking.toggleTracking(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: active 
                    ? [Colors.red.shade600, Colors.red.shade800] 
                    : [primaryColor, accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: (active ? Colors.red : primaryColor).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                Icon(active ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded, color: Colors.white, size: 55),
                const SizedBox(height: 10),
                Text(
                  active ? "BERHENTI MENARIK" : "MULAI MENARIK!",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                Text(
                  active ? "Posisi Anda sedang dipantau penumpang" : "Ketuk untuk online di peta Medan",
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicleInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.directions_bus_rounded, color: primaryColor, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("KPUM 64 (BK 1234 AA)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text("Trayek: Amplas - Pinang Baris", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.verified_user_rounded, color: Colors.blue, size: 20),
        ],
      ),
    );
  }
}