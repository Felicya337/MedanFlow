import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'driver_management_screen.dart';
import 'traffic_heatmap_screen.dart';
import 'angkot_tracking_screen.dart';
import 'admin_analytics_screen.dart';
import 'driver_approval_screen.dart';
import 'landing_page.dart'; // Import Landing Page

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;

  final Color primaryColor = const Color(0xFF00796B);
  final Color adminIndigo = const Color(0xFF1A237E);

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService().baseUrl}/weather/current"),
      );
      if (response.statusCode == 200) {
        setState(() {
          _weatherData = jsonDecode(response.body);
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal muat cuaca admin: $e");
      setState(() => _isLoadingWeather = false);
    }
  }

  // LOGIKA LOGOUT DENGAN KONFIRMASI
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout Admin"),
        content: const Text(
          "Apakah Anda ingin keluar dari Pusat Kendali Dishub?",
        ),
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
            style: ElevatedButton.styleFrom(backgroundColor: adminIndigo),
            child: const Text("KELUAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 140.0,
            pinned: true,
            elevation: 0,
            backgroundColor: adminIndigo,
            automaticallyImplyLeading: false, // Menghilangkan tombol back
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
              title: const Text(
                "DISHUB MEDAN",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [adminIndigo, primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _fetchWeather,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
              // TOMBOL LOGOUT ADMIN (BARU)
              IconButton(
                onPressed: _showLogoutConfirmation,
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
              const SizedBox(width: 10),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWeatherCard(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Status Operasional",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildQuickStats(),
                      const SizedBox(height: 30),
                      const Text(
                        "Modul Manajemen",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildModuleTile(
                        context,
                        "Kelola Driver & Armada",
                        "Data personil dan unit angkot.",
                        Icons.people_alt_rounded,
                        Colors.blue,
                        const DriverManagementScreen(),
                      ),
                      _buildModuleTile(
                        context,
                        "Persetujuan Akun",
                        "Aktivasi pendaftaran driver baru.",
                        Icons.how_to_reg_rounded,
                        Colors.amber.shade800,
                        const DriverApprovalScreen(),
                      ),
                      _buildModuleTile(
                        context,
                        "Monitoring Real-time",
                        "Pantau pergerakan angkot aktif.",
                        Icons.gps_fixed_rounded,
                        Colors.teal,
                        const AngkotTrackingScreen(),
                      ),
                      _buildModuleTile(
                        context,
                        "Peta Panas (Heatmap)",
                        "Analisis titik kemacetan.",
                        Icons.whatshot_rounded,
                        Colors.orange,
                        const TrafficHeatmapScreen(),
                      ),
                      _buildModuleTile(
                        context,
                        "Analisis Data AI",
                        "Laporan tren mingguan.",
                        Icons.analytics_rounded,
                        Colors.purple,
                        const AdminAnalyticsScreen(),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (_isLoadingWeather)
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: adminIndigo.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Cuaca Lapangan Saat Ini",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _weatherData?['condition'] ?? "Loading...",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Lokasi: Medan Kota",
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          Column(
            children: [
              const Icon(Icons.cloudy_snowing, color: Colors.white, size: 40),
              Text(
                _weatherData?['temp'] ?? "--",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statBox("142", "Angkot Online", Icons.directions_bus, Colors.teal),
        const SizedBox(width: 15),
        _statBox("Low", "Index Macet", Icons.speed, Colors.green),
      ],
    );
  }

  Widget _statBox(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleTile(
    BuildContext context,
    String title,
    String desc,
    IconData icon,
    Color color,
    Widget target,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => target)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          desc,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }
}
