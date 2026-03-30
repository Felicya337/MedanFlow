import 'package:flutter/material.dart';
import 'package:flutter_medan_flow/services/api_service.dart';
import 'login_screen.dart';
import 'guest_home_screen.dart';
import 'route_recommendation_screen.dart';
import 'travel_time_prediction_screen.dart';
import 'traffic_heatmap_screen.dart';
import 'angkot_tracking_screen.dart';
import 'notification_screen.dart'; // Import Baru

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _unreadNotif = 0;
  bool _showCriticalBanner = false;
  String _bannerMessage = "";

  @override
  void initState() {
    super.initState();
    _checkNotifications();
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
      debugPrint("Check Notif Failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00796B);
    const Color scaffoldBg = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // APP BAR DENGAN NOTIFIKASI LONCENG
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryColor,
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    ),
                  ),
                  if (_unreadNotif > 0)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '$_unreadNotif',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              title: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Horas, Medan! 🌞",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Mau ke mana hari ini?",
                    style: TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
              background: Container(color: primaryColor),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CRITICAL ALERT BANNER (Hanya muncul jika ada notif kritis)
                if (_showCriticalBanner)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.red.shade50,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _bannerMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              setState(() => _showCriticalBanner = false),
                        ),
                      ],
                    ),
                  ),

                // QUICK ACTIONS
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      _buildQuickAction(
                        context,
                        "Rute Pintar",
                        Icons.auto_awesome_outlined,
                        Colors.blue.shade700,
                        const RouteRecommendationScreen(),
                      ),
                      const SizedBox(width: 15),
                      _buildQuickAction(
                        context,
                        "Live Tracking",
                        Icons.gps_fixed,
                        Colors.teal.shade800,
                        const AngkotTrackingScreen(),
                      ),
                    ],
                  ),
                ),

                // INFORMASI TRAFIK BANNER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: primaryColor),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Cek prediksi kemacetan 30 menit ke depan di sini.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TrafficHeatmapScreen(),
                            ),
                          ),
                          child: const Text("Cek"),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Solusi Cerdas Kami",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                _buildMainFeature(
                  context,
                  Icons.analytics_outlined,
                  "Prediksi Waktu Tempuh",
                  "Estimasi perjalanan akurat berbasis AI.",
                  const TravelTimePredictionScreen(),
                ),
                _buildMainFeature(
                  context,
                  Icons.map_rounded,
                  "Heatmap Kepadatan",
                  "Visualisasi kemacetan jalanan Medan.",
                  const TrafficHeatmapScreen(),
                ),
                _buildMainFeature(
                  context,
                  Icons.bus_alert_outlined,
                  "Lokasi Angkot (Real-time)",
                  "Pantau armada angkot & estimasi kedatangan.",
                  const AngkotTrackingScreen(),
                ),

                const SizedBox(height: 40),

                // LOGIN AREA
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF004D40), Color(0xFF00796B)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Punya akses Driver atau Petugas?",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "LOGIN DASHBOARD",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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

  Widget _buildQuickAction(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    Widget target,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => target)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainFeature(
    BuildContext context,
    IconData icon,
    String title,
    String desc,
    Widget target,
  ) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => target)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF00796B)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    desc,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
