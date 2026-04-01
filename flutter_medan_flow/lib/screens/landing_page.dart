import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_medan_flow/services/api_service.dart';
import 'login_screen.dart';
import 'guest_home_screen.dart';
import 'route_recommendation_screen.dart';
import 'travel_time_prediction_screen.dart';
import 'traffic_heatmap_screen.dart';
import 'angkot_tracking_screen.dart';
import 'notification_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _unreadNotif = 0;
  bool _showCriticalBanner = false;
  String _bannerMessage = "";
  
  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _checkNotifications();
    _fetchWeather();
  }

  Future<void> _checkNotifications() async {
    try {
      final data = await ApiService().getNotifications();
      setState(() {
        _unreadNotif = data['unread_count'];
        if (_unreadNotif > 0) {
          _showCriticalBanner = true;
          _bannerMessage = data['alerts'][0]['message'];
        }
      });
    } catch (e) {
      debugPrint("Check Notif Failed: $e");
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final response = await http.get(Uri.parse("${ApiService().baseUrl}/weather/current"));
      if (response.statusCode == 200) {
        setState(() {
          _weatherData = jsonDecode(response.body);
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch Weather Failed: $e");
      setState(() => _isLoadingWeather = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisi palet warna untuk konsistensi gradasi
    const Color gradStart = Color(0xFF00796B); // Teal utama
    const Color gradEnd = Color(0xFF004D40);   // Teal gelap (sama seperti card cuaca)
    const Color scaffoldBg = Color(0xFFF8F9FA); // Abu-abu muda latar belakang

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. APP BAR DENGAN GRADASI TERPADU
          SliverAppBar(
            expandedHeight: 100.0,
            floating: false,
            pinned: true,
            elevation: 0,
            stretch: true,
            backgroundColor: gradStart,
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationScreen()),
                    ),
                  ),
                  if (_unreadNotif > 0)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text('$_unreadNotif', style: const TextStyle(color: Colors.white, fontSize: 8), textAlign: TextAlign.center),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                "MEDAN FLOW",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gradStart, gradEnd],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. ZONA GRADASI TRANSISI (Header Fading ke Background)
                Stack(
                  children: [
                    // Background gradasi yang memudar ke warna scaffold
                    Container(
                      height: 180,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [gradEnd, scaffoldBg],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Konten di atas gradasi transisi
                    Column(
                      children: [
                        if (_showCriticalBanner)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(_bannerMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                  onPressed: () => setState(() => _showCriticalBanner = false),
                                ),
                              ],
                            ),
                          ),
                        _buildWeatherCard(gradStart, gradEnd),
                      ],
                    ),
                  ],
                ),

                // 3. QUICK ACTIONS SECTION
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
                  child: Row(
                    children: [
                      _buildQuickAction(context, "Rute Pintar", Icons.auto_awesome_outlined, Colors.blue.shade700, const RouteRecommendationScreen()),
                      const SizedBox(width: 15),
                      _buildQuickAction(context, "Live Tracking", Icons.gps_fixed, Colors.teal.shade800, const AngkotTrackingScreen()),
                    ],
                  ),
                ),

                // 4. INFORMASI TRAFIK BANNER
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: gradStart),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text("Cek prediksi kemacetan 30 menit ke depan di sini.", style: TextStyle(fontSize: 12, color: Colors.black87)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrafficHeatmapScreen())),
                          child: const Text("Cek", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text("Solusi Cerdas Kami", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
                const SizedBox(height: 15),

                _buildMainFeature(context, Icons.analytics_outlined, "Prediksi Waktu Tempuh", "Estimasi perjalanan akurat berbasis AI.", const TravelTimePredictionScreen(), gradStart),
                _buildMainFeature(context, Icons.map_rounded, "Heatmap Kepadatan", "Visualisasi kemacetan jalanan Medan.", const TrafficHeatmapScreen(), gradStart),
                _buildMainFeature(context, Icons.bus_alert_outlined, "Lokasi Angkot (Real-time)", "Pantau armada angkot & estimasi kedatangan.", const AngkotTrackingScreen(), gradStart),

                const SizedBox(height: 40),

                // 5. LOGIN AREA
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [gradEnd, gradStart]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: gradStart.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    children: [
                      const Text("Punya akses Driver atau Petugas?", style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: gradStart,
                          minimumSize: const Size(double.infinity, 50),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text("LOGIN DASHBOARD", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(Color start, Color end) {
    if (_isLoadingWeather) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (_weatherData == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [start, end], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Kondisi Medan Saat Ini", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(
                      _weatherData!['condition'],
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(_weatherData!['location'], style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  Icon(
                    _weatherData!['icon'] == 'rainy' ? Icons.cloudy_snowing : (_weatherData!['icon'] == 'cloudy' ? Icons.cloud : Icons.wb_sunny),
                    color: Colors.white, size: 48,
                  ),
                  Text("${_weatherData!['temp']}°C", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24, thickness: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _weatherInfoTile(Icons.water_drop_outlined, "Lembab", _weatherData!['humidity']),
              _weatherInfoTile(Icons.air, "Angin", _weatherData!['wind_speed']),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(15)),
            child: Text(_weatherData!['description'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontStyle: FontStyle.italic)),
          )
        ],
      ),
    );
  }

  Widget _weatherInfoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Text("$label: ", style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, Color color, Widget target) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => target)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainFeature(BuildContext context, IconData icon, String title, String desc, Widget target, Color themeColor) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => target)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: themeColor.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: themeColor),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 24),
          ],
        ),
      ),
    );
  }
}