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
    try {
      final response = await http.get(Uri.parse("${_apiService.baseUrl}/driver/insights"));
      if (response.statusCode == 200) {
        setState(() {
          _insights = jsonDecode(response.body);
          _loadingInsight = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal load insight: $e");
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
        title: const Text("MEDAN FLOW - DRIVER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchInsights),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header & Quick Stats
            _buildStatusHeader(primaryColor),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Analisis Kondisi Hari Ini", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  // 2. Insight Cards (Weather & Traffic)
                  _loadingInsight 
                    ? const Center(child: CircularProgressIndicator()) 
                    : _buildInsightSection(),

                  const SizedBox(height: 25),
                  
                  // 3. Tombol Utama Menarik
                  _buildTrackingButton(context),

                  const SizedBox(height: 25),
                  
                  // 4. Info Kendaraan
                  _buildVehicleInfo(),
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
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Consumer<TrackingProvider>(
        builder: (context, tracking, child) {
          return Row(
            children: [
              const CircleAvatar(radius: 30, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white, size: 30)),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Bang Ucok Sopir", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(tracking.isTracking ? "• SEDANG BERTUGAS" : "• SEDANG ISTIRAHAT", 
                    style: TextStyle(color: tracking.isTracking ? Colors.greenAccent : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildInsightSection() {
    return Column(
      children: [
        Row(
          children: [
            _insightTile("Cuaca", _insights!['weather']['condition'], Icons.wb_cloudy_outlined, Colors.blue),
            const SizedBox(width: 15),
            _insightTile("Lalu Lintas", _insights!['traffic']['description'], Icons.traffic_outlined, Colors.orange),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _insights!['is_good_to_work'] ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _insights!['is_good_to_work'] ? Colors.green.shade200 : Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(_insights!['is_good_to_work'] ? Icons.check_circle : Icons.warning, color: _insights!['is_good_to_work'] ? Colors.green : Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_insights!['recommendation'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _insightTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: active ? [Colors.red.shade400, Colors.red.shade700] : [const Color(0xFF00897B), const Color(0xFF00695C)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: (active ? Colors.red : Colors.teal).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Column(
              children: [
                Icon(active ? Icons.stop_circle : Icons.play_circle_fill, color: Colors.white, size: 50),
                const SizedBox(height: 10),
                Text(active ? "BERHENTI MENARIK" : "MULAI MENARIK!", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(active ? "GPS Aktif - Penumpang memantau Anda" : "Klik untuk online di peta penumpang", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: const Row(
        children: [
          Icon(Icons.directions_bus, color: Color(0xFF00796B), size: 30),
          SizedBox(width: 15),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("KPUM 64 (BK 1234 AA)", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Trayek: Amplas - Pinang Baris", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
          Icon(Icons.verified, color: Colors.blue, size: 20),
        ],
      ),
    );
  }
}