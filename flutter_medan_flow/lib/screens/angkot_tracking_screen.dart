import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class AngkotTrackingScreen extends StatefulWidget {
  const AngkotTrackingScreen({super.key});

  @override
  State<AngkotTrackingScreen> createState() => _AngkotTrackingScreenState();
}

class _AngkotTrackingScreenState extends State<AngkotTrackingScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();
  
  List<Marker> _markers = [];
  Timer? _timer;
  bool _isLoading = true;
  List<dynamic> _angkotList = [];
  
  // Warna Tema Medan Flow
  final Color primaryColor = const Color(0xFF00796B);

  @override
  void initState() {
    super.initState();
    _fetchData();
    // Refresh posisi angkot setiap 10 detik agar terasa real-time
    _timer = Timer.periodic(const Duration(seconds: 10), (t) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _apiService.getActiveAngkots();
      if (mounted) {
        setState(() {
          _angkotList = data;
          _updateMarkers(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("OSM Tracking Error: $e");
    }
  }

  void _updateMarkers(List<dynamic> data) {
    List<Marker> newMarkers = [];
    for (var angkot in data) {
      // Tentukan warna berdasarkan kepadatan
      Color statusColor = angkot['crowd_status'] == 'Penuh' ? Colors.red : primaryColor;
      
      newMarkers.add(
        Marker(
          point: LatLng(
            double.parse(angkot['latitude'].toString()), 
            double.parse(angkot['longitude'].toString())
          ),
          width: 70,
          height: 70,
          child: GestureDetector(
            onTap: () => _focusOnAngkot(angkot),
            child: Column(
              children: [
                // Label Nomor Angkot
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    angkot['angkot_number'],
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
                // Icon Bus dengan Glow
                Icon(Icons.directions_bus_rounded, color: statusColor, size: 30),
              ],
            ),
          ),
        ),
      );
    }
    setState(() => _markers = newMarkers);
  }

  void _focusOnAngkot(dynamic angkot) {
    _mapController.move(
      LatLng(double.parse(angkot['latitude'].toString()), double.parse(angkot['longitude'].toString())),
      15.0
    );
  }

  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Live Tracking Angkot", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white.withOpacity(0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. Peta Full Screen
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(3.5952, 98.6722),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.medanflow.app',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),

          // 2. Zoom Controls
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height * 0.3,
            child: Column(
              children: [
                _buildMapButton(Icons.add, _zoomIn),
                const SizedBox(height: 10),
                _buildMapButton(Icons.remove, _zoomOut),
                const SizedBox(height: 10),
                _buildMapButton(Icons.my_location, () => _mapController.move(const LatLng(3.5952, 98.6722), 13)),
              ],
            ),
          ),

          // 3. Panel Informasi Angkot (Draggable)
          _buildDraggableAngkotList(),

          if (_isLoading) 
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildMapButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: IconButton(icon: Icon(icon, color: primaryColor), onPressed: onTap),
    );
  }

  Widget _buildDraggableAngkotList() {
    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.1,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Armada Aktif", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
                    Text("${_angkotList.length} Unit", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _angkotList.isEmpty
                ? const Center(child: Text("Tidak ada angkot yang beroperasi saat ini"))
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _angkotList.length,
                    itemBuilder: (context, index) {
                      final angkot = _angkotList[index];
                      return _buildAngkotCard(angkot);
                    },
                  ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAngkotCard(dynamic angkot) {
    bool isFull = angkot['crowd_status'] == 'Penuh';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: () => _focusOnAngkot(angkot),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isFull ? Colors.red : primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.directions_bus_filled_rounded, color: isFull ? Colors.red : primaryColor),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Angkot ${angkot['angkot_number']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(angkot['route_name'] ?? "Rute Medan", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _statusBadge(angkot['crowd_status']),
                      const SizedBox(width: 10),
                      const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("${angkot['eta_minutes']} Menit", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    bool isFull = status == 'Penuh';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isFull ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isFull ? Colors.red : Colors.green,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}