import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class DriverManagementScreen extends StatefulWidget {
  const DriverManagementScreen({super.key});

  @override
  State<DriverManagementScreen> createState() => _DriverManagementScreenState();
}

class _DriverManagementScreenState extends State<DriverManagementScreen> {
  final ApiService _apiService = ApiService();
  List _drivers = [];
  List _filteredDrivers = [];
  List _angkots = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  final Color adminIndigo = const Color(0xFF1A237E);
  final Color primaryTeal = const Color(0xFF00796B);

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredDrivers = _drivers.where((d) {
        final name = d['user']['name'].toString().toLowerCase();
        final plate = d['vehicle_plate'].toString().toLowerCase();
        final query = _searchController.text.toLowerCase();
        return name.contains(query) || plate.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final dRes = await http.get(
        Uri.parse("${_apiService.baseUrl}/admin/drivers"),
        headers: {'Authorization': 'Bearer $token'},
      );

      final aRes = await http.get(
        Uri.parse("${_apiService.baseUrl}/admin/angkots"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (dRes.statusCode == 200 && aRes.statusCode == 200) {
        setState(() {
          _drivers = jsonDecode(dRes.body);
          _filteredDrivers = _drivers;
          _angkots = jsonDecode(aRes.body);
        });
      }
    } catch (e) {
      _showSnackBar("Koneksi bermasalah. Cek server Anda.", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Hapus Driver?"),
        content: Text("Akun driver $name akan dihapus secara permanen dari sistem."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("BATAL")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDriver(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("HAPUS", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDriver(int id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      final res = await http.delete(
        Uri.parse("${_apiService.baseUrl}/admin/drivers/$id"),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        _fetchData();
        _showSnackBar("Driver berhasil dihapus", Colors.green);
      }
    } catch (e) {
      _showSnackBar("Gagal menghapus driver", Colors.red);
    }
  }

  void _showForm({Map? driver}) {
    final nameCtrl = TextEditingController(text: driver?['user']['name'] ?? "");
    final emailCtrl = TextEditingController(text: driver?['user']['email'] ?? "");
    final passCtrl = TextEditingController();
    final plateCtrl = TextEditingController(text: driver?['vehicle_plate'] ?? "");
    int? selectedAngkot = driver?['angkot_id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 25, right: 25, top: 20
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text(driver == null ? "Tambah Personil Baru" : "Perbarui Data Driver", 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
              _buildInput(nameCtrl, "Nama Lengkap", Icons.person_outline),
              _buildInput(emailCtrl, "Email Address", Icons.email_outlined),
              if (driver == null) _buildInput(passCtrl, "Password", Icons.lock_outline, obscure: true),
              _buildInput(plateCtrl, "Plat Kendaraan (BK)", Icons.directions_bus_outlined),
              
              DropdownButtonFormField<int>(
                value: selectedAngkot,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: "Pilih Armada Angkot",
                  prefixIcon: Icon(Icons.airport_shuttle, color: adminIndigo),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                items: _angkots.map<DropdownMenuItem<int>>((a) => 
                  DropdownMenuItem(value: a['id'], child: Text("Angkot ${a['angkot_number']}"))).toList(),
                onChanged: (val) => selectedAngkot = val,
              ),
              
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: adminIndigo,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                onPressed: () async {
                  if (selectedAngkot == null || nameCtrl.text.isEmpty) {
                    _showSnackBar("Harap lengkapi form", Colors.orange);
                    return;
                  }
                  
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  String? token = prefs.getString('token');

                  final body = {
                    'name': nameCtrl.text,
                    'email': emailCtrl.text,
                    'password': passCtrl.text,
                    'angkot_id': selectedAngkot.toString(),
                    'vehicle_plate': plateCtrl.text,
                  };

                  final url = driver == null 
                    ? "${_apiService.baseUrl}/admin/drivers"
                    : "${_apiService.baseUrl}/admin/drivers/${driver['id']}";
                  
                  final response = driver == null 
                    ? await http.post(Uri.parse(url), body: body, headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'})
                    : await http.put(Uri.parse(url), body: body, headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});

                  if (response.statusCode == 200) {
                    Navigator.pop(context);
                    _fetchData();
                    _showSnackBar("Data berhasil disimpan", Colors.green);
                  } else {
                    _showSnackBar("Gagal menyimpan data", Colors.red);
                  }
                },
                child: const Text("SIMPAN PERUBAHAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label, 
          prefixIcon: Icon(icon, color: adminIndigo),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Manajemen Driver", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), 
        backgroundColor: adminIndigo, 
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: adminIndigo,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Personil: ${_drivers.length}", style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    const Icon(Icons.info_outline, color: Colors.white30),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Cari nama atau plat nomor...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: adminIndigo))
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  color: adminIndigo,
                  child: _filteredDrivers.isEmpty 
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _filteredDrivers.length,
                        itemBuilder: (context, index) {
                          final d = _filteredDrivers[index];
                          return _buildDriverCard(d);
                        },
                      ),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00BFA5),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("TAMBAH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showForm(),
      ),
    );
  }

  Widget _buildDriverCard(dynamic d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: primaryTeal.withOpacity(0.1),
              child: Text(d['user']['name'][0].toUpperCase(), style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 20)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d['user']['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  // SOLUSI OVERFLOW: Ganti Row ke Wrap agar teks otomatis pindah ke baris baru jika tidak muat
                  Wrap(
                    spacing: 10,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.credit_card, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(d['vehicle_plate'], style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.airport_shuttle, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text("Unit: ${d['angkot']['angkot_number']}", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            // Aksi Edit & Delete
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  icon: const Icon(Icons.edit_outlined, color: Colors.orange, size: 20), 
                  onPressed: () => _showForm(driver: d)
                ),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), 
                  onPressed: () => _confirmDelete(d['id'], d['user']['name'])
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text("Data tidak ditemukan", style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}