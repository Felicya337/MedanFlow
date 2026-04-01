import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/tracking_provider.dart';
import '../services/api_service.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  Map<String, dynamic>? _insights;
  bool _loadingInsight = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchInsights();
  }

  Future<void> _fetchInsights() async {
    setState(() => _loadingInsight = true);
    try {
      final response = await http.get(Uri.parse("${ApiService().baseUrl}/driver/insights"));
      if (response.statusCode == 200) {
        setState(() {
          _insights = jsonDecode(response.body);
          _loadingInsight = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal load insight: $e");
      setState(() => _loadingInsight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00796B);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: const Text(
          "MEDAN FLOW - DRIVER",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, letterSpacing: 1.2),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchInsights,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. Header Profile & Status
            _buildStatusHeader(primaryColor),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Kondisi Operasional",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                  ),
                  const SizedBox(height: 15),

                  // 2. Insight Section (Weather & Traffic Terintegrasi)
                  _loadingInsight
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(color: primaryColor),
                          ),
                        )
                      : _buildInsightSection(),

                  const SizedBox(height: 25),

                  // 3. Tombol Utama Menarik (Action)
                  _buildTrackingButton(context),

                  const SizedBox(height: 25),

                  // 4. Info Kendaraan & Armada
                  _buildVehicleInfo(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Consumer<TrackingProvider>(
        builder: (context, tracking, child) {
          return Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white, size: 35),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Bang Ucok Sopir",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: tracking.isTracking ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tracking.isTracking ? "SEDANG BERTUGAS" : "SEDANG ISTIRAHAT",
                          style: TextStyle(
                            color: tracking.isTracking ? Colors.greenAccent : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildInsightSection() {
    if (_insights == null) return const SizedBox.shrink();

    // Logika Icon Cuaca Dinamis
    IconData weatherIcon = Icons.wb_sunny_outlined;
    Color weatherColor = Colors.orange;
    String condition = _insights!['weather']['condition'].toString().toLowerCase();

    if (condition.contains('hujan') || condition.contains('rain')) {
      weatherIcon = Icons.cloudy_snowing;
      weatherColor = Colors.blue;
    } else if (condition.contains('awan') || condition.contains('cloud')) {
      weatherIcon = Icons.wb_cloudy_outlined;
      weatherColor = Colors.blueGrey;
    }

    return Column(
      children: [
        Row(
          children: [
            // TILE CUACA (Update Baru)
            _insightTile(
              "Cuaca Medan",
              _insights!['weather']['temp'] ?? "--",
              _insights!['weather']['condition'],
              weatherIcon,
              weatherColor,
            ),
            const SizedBox(width: 15),
            // TILE LALU LINTAS
            _insightTile(
              "Lalu Lintas",
              _insights!['traffic']['level'].toString().toUpperCase(),
              _insights!['traffic']['description'],
              Icons.traffic_outlined,
              Colors.deepOrange,
            ),
          ],
        ),
        const SizedBox(height: 15),
        // Kartu Rekomendasi AI
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _insights!['is_good_to_work'] ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _insights!['is_good_to_work'] ? Colors.green.shade200 : Colors.red.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _insights!['is_good_to_work'] ? Icons.check_circle_rounded : Icons.info_rounded,
                color: _insights!['is_good_to_work'] ? Colors.green.shade700 : Colors.red.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _insights!['is_good_to_work'] ? "Saran Sistem: Layak Jalan" : "Peringatan Sistem",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _insights!['is_good_to_work'] ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _insights!['recommendation'],
                      style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _insightTile(String label, String value, String subValue, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF263238))),
            Text(
              subValue,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
                    ? [Colors.red.shade400, Colors.red.shade700]
                    : [const Color(0xFF00897B), const Color(0xFF00695C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: (active ? Colors.red : const Color(0xFF00796B)).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                Icon(
                  active ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 55,
                ),
                const SizedBox(height: 10),
                Text(
                  active ? "BERHENTI MENARIK" : "MULAI MENARIK!",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  active ? "GPS Aktif • Perjalanan sedang direkam" : "Aktifkan GPS agar penumpang melihat Anda",
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
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
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.directions_bus_rounded, color: Color(0xFF00796B), size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "KPUM 64 (BK 1234 AA)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF263238)),
                ),
                const Text(
                  "Rute Resmi: Amplas - Pinang Baris",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_user_rounded, color: Colors.blue, size: 20),
        ],
      ),
    );
  }
}