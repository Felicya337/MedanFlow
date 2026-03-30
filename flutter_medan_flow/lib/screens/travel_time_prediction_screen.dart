import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class TravelTimePredictionScreen extends StatefulWidget {
  const TravelTimePredictionScreen({super.key});

  @override
  State<TravelTimePredictionScreen> createState() => _TravelTimePredictionScreenState();
}

class _TravelTimePredictionScreenState extends State<TravelTimePredictionScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = false;
  int _selectedRouteId = 1;

  final Color primaryColor = const Color(0xFF00796B);

  Future<void> _getPrediction() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("${ApiService().baseUrl}/predict-time?route_id=$_selectedRouteId"),
      );
      if (response.statusCode == 200) {
        setState(() => _data = jsonDecode(response.body));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal terhubung ke server Medan Flow")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Analisis Waktu AI", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Insight
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Smart Prediction", 
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text("Data diproses berdasarkan trafik & cuaca terkini", 
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // 2. Route Selector Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)],
              ),
              child: Column(
                children: [
                  _buildRouteInputVisual(),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedRouteId,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text("KPUM 64: Amplas - Pinang Baris")),
                          DropdownMenuItem(value: 2, child: Text("Morina 81: Simalingkar - Amplas")),
                        ],
                        onChanged: (val) => setState(() => _selectedRouteId = val!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Action Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _getPrediction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("ANALISIS ESTIMASI SEKARANG", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 30),

            // 4. Result Area
            if (_data != null && !_isLoading) ...[
              _buildHeroResultCard(),
              const SizedBox(height: 25),
              const Text("Detail Faktor & Akurasi", 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildDetailGrid(),
              const SizedBox(height: 40),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInputVisual() {
    return Row(
      children: [
        const Column(
          children: [
            Icon(Icons.radio_button_checked, color: Colors.blue, size: 18),
            Container(width: 2, height: 30, color: Colors.grey),
            Icon(Icons.location_on, color: Colors.red, size: 18),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_selectedRouteId == 1 ? "Terminal Amplas" : "Simalingkar", 
                style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
              Text(_selectedRouteId == 1 ? "Pinang Baris" : "Terminal Amplas", 
                style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildHeroResultCard() {
    final statusColor = _getStatusColor(_data!['status_color']);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          const Text("ESTIMASI PERJALANAN", 
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Text(_data!['predicted_time'], 
            style: const TextStyle(color: Colors.white, fontSize: 54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(_data!['congestion_level'], 
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _heroInfoItem("Normal", _data!['normal_time']),
              _heroInfoItem("Delay", _data!['delay']),
            ],
          )
        ],
      ),
    );
  }

  Widget _heroInfoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildDetailGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.4,
      children: [
        _buildDetailItem("Jarak Tempuh", _data!['distance'], Icons.map_outlined, Colors.blue),
        _buildDetailItem("Faktor Cuaca", _data!['prediction_factors']['weather'], Icons.wb_cloudy_outlined, Colors.orange),
        _buildDetailItem("Kepersisiam AI", _data!['prediction_factors']['confidence_level'], Icons.verified_outlined, Colors.teal),
        _buildDetailItem("Update Terakhir", _data!['current_time'], Icons.access_time, Colors.grey),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Color _getStatusColor(String colorName) {
    switch (colorName) {
      case 'red': return const Color(0xFFE53935);
      case 'orange': return const Color(0xFFFB8C00);
      case 'blue': return const Color(0xFF1E88E5);
      default: return const Color(0xFF43A047);
    }
  }
}