import 'package:flutter/material.dart';
import 'driver_management_screen.dart';
import 'traffic_heatmap_screen.dart';
import 'angkot_tracking_screen.dart';
import 'admin_analytics_screen.dart'; // Kita akan buat file ini

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color adminPrimary = Color(0xFF1A237E); // Indigo Deep
    const Color scaffoldBg = Color(0xFFF4F7F9);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // 1. Header Dashboard
          SliverAppBar(
            expandedHeight: 150.0,
            pinned: true,
            backgroundColor: adminPrimary,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("DISHUB MEDAN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text("Pusat Kendali Transportasi Kota", style: TextStyle(fontSize: 10, color: Colors.white70)),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                    begin: Alignment.topLeft,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Ringkasan Cepat (Statis)
                  const Text("Status Terakhir", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildQuickStats(),

                  const SizedBox(height: 30),

                  // 3. Modul Operasional (Menu Utama)
                  const Text("Modul Operasional", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  _buildModuleTile(
                    context,
                    "Kelola Driver & Armada",
                    "Tambah, Edit, dan Hapus data pengemudi Medan Flow.",
                    Icons.people_alt_rounded,
                    Colors.blue,
                    const DriverManagementScreen(),
                  ),
                  _buildModuleTile(
                    context,
                    "Monitoring Real-time",
                    "Pantau posisi seluruh angkot aktif di peta kota Medan.",
                    Icons.gps_fixed_rounded,
                    Colors.teal,
                    const AngkotTrackingScreen(),
                  ),
                  _buildModuleTile(
                    context,
                    "Visualisasi Heatmap",
                    "Analisis titik kemacetan melalui peta panas dinamis.",
                    Icons.whatshot_rounded,
                    Colors.orange,
                    const TrafficHeatmapScreen(),
                  ),
                  _buildModuleTile(
                    context,
                    "Analisis & Laporan",
                    "Lihat grafik tren kemacetan dan performa transportasi.",
                    Icons.analytics_rounded,
                    Colors.purple,
                    const AdminAnalyticsScreen(),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statBox("142", "Angkot Aktif", Icons.directions_bus, Colors.teal),
        const SizedBox(width: 15),
        _statBox("12", "Titik Macet", Icons.warning_amber_rounded, Colors.red),
      ],
    );
  }

  Widget _statBox(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleTile(BuildContext context, String title, String desc, IconData icon, Color color, Widget target) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => target)),
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}