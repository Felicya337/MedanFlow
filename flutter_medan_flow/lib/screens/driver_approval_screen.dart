import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class DriverApprovalScreen extends StatefulWidget {
  const DriverApprovalScreen({super.key});

  @override
  State<DriverApprovalScreen> createState() => _DriverApprovalScreenState();
}

class _DriverApprovalScreenState extends State<DriverApprovalScreen> {
  final ApiService _apiService = ApiService();
  List _pendingDrivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingDrivers();
  }

  Future<void> _fetchPendingDrivers() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse("${_apiService.baseUrl}/admin/pending-drivers"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() => _pendingDrivers = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processApproval(int id, bool isApprove) async {
    String action = isApprove ? 'approve' : 'reject';
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse("${_apiService.baseUrl}/admin/$action-driver/$id"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        String msg = jsonDecode(response.body)['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: isApprove ? Colors.teal : Colors.red),
        );
        _fetchPendingDrivers();
      }
    } catch (e) {
      debugPrint("Process Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color adminIndigo = Color(0xFF1A237E);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: const Text("Persetujuan Driver", 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: adminIndigo,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingDrivers.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchPendingDrivers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _pendingDrivers.length,
                    itemBuilder: (context, index) {
                      final driver = _pendingDrivers[index];
                      return _buildDriverCard(driver);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          const Text("Semua permohonan telah diproses", 
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          TextButton(onPressed: _fetchPendingDrivers, child: const Text("Refresh data")),
        ],
      ),
    );
  }

  Widget _buildDriverCard(dynamic driver) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header Info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.indigo.shade50,
                  child: const Icon(Icons.person_search, color: Colors.indigo),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver['user']['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(driver['user']['email'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Text("PENDING", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          const Divider(height: 0),
          // Detail Kendaraan
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _detailColumn("Plat Nomor", driver['vehicle_plate']),
                _detailColumn("Armada", driver['angkot']['angkot_number']),
                _detailColumn("Rute", driver['angkot']['route']['name']),
              ],
            ),
          ),
          // Tombol Aksi
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _processApproval(driver['id'], false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("TOLAK", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _processApproval(driver['id'], true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00796B),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("SETUJUI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _detailColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}