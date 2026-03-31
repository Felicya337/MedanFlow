import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  bool _isLoading = true;
  List<dynamic> _chartData = [];

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    try {
      final response = await http.get(Uri.parse("${ApiService().baseUrl}/admin/stats"));
      if (response.statusCode == 200) {
        setState(() {
          _chartData = jsonDecode(response.body)['chart_data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Analytics Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Analisis & Laporan", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Grafik Kemacetan Mingguan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  // Bar Chart Simulation
                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _chartData.map((d) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text("${d['value']}%", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Container(
                              width: 30,
                              height: (d['value'] * 1.5).toDouble(),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Colors.indigo, Colors.blue]),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(d['day'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text("Insight Mobilitas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildInsightCard("Puncak Kemacetan", "Terjadi setiap hari Jumat pukul 17:00 - 19:00 WIB.", Icons.trending_up, Colors.red),
                  _buildInsightCard("Rute Terpadat", "Trayek KPUM 64 (Amplas - Pinang Baris).", Icons.map, Colors.blue),
                ],
              ),
            ),
    );
  }

  Widget _buildInsightCard(String title, String desc, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF8F9FA),
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
      ),
    );
  }
}