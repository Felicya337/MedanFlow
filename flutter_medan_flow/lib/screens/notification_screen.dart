import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await _apiService.getNotifications();
      setState(() {
        _alerts = data['alerts'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Notif Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Pusat Notifikasi", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadNotifications, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final item = _alerts[index];
                    return _buildNotificationCard(item);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text("Tidak ada notifikasi baru", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(dynamic item) {
    IconData icon = Icons.info;
    Color color = Colors.blue;

    if (item['type'] == 'weather') {
      icon = Icons.cloudy_snowing;
      color = Colors.blue;
    } else if (item['type'] == 'traffic') {
      icon = Icons.traffic;
      color = Colors.red;
    } else {
      icon = Icons.lightbulb_outline;
      color = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: item['is_critical'] ? Border.all(color: Colors.red.shade100, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(item['time'], style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(item['message'], style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }
}