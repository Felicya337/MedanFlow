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
  List _angkots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // Ambil data driver
      final dRes = await http.get(
        Uri.parse("${_apiService.baseUrl}/admin/drivers"),
        headers: {'Authorization': 'Bearer $token'},
      );

      // Ambil data angkot untuk dropdown
      final aRes = await http.get(
        Uri.parse("${_apiService.baseUrl}/admin/angkots"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (dRes.statusCode == 200 && aRes.statusCode == 200) {
        setState(() {
          _drivers = jsonDecode(dRes.body);
          _angkots = jsonDecode(aRes.body);
        });
      } else {
        _showSnackBar("Gagal mengambil data dari server");
      }
    } catch (e) {
      _showSnackBar("Error Koneksi: Pastikan Laravel jalan");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _deleteDriver(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final res = await http.delete(
      Uri.parse("${_apiService.baseUrl}/admin/drivers/$id"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      _fetchData();
      _showSnackBar("Driver berhasil dihapus");
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, 
            left: 20, right: 20, top: 20
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(driver == null ? "Tambah Driver" : "Edit Driver", 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildInput(nameCtrl, "Nama Lengkap", Icons.person),
                _buildInput(emailCtrl, "Email", Icons.email),
                if (driver == null) _buildInput(passCtrl, "Password", Icons.lock, obscure: true),
                _buildInput(plateCtrl, "Plat Nomor (BK)", Icons.directions_car),
                
                DropdownButtonFormField<int>(
                  value: selectedAngkot,
                  decoration: const InputDecoration(labelText: "Pilih Armada"),
                  items: _angkots.map<DropdownMenuItem<int>>((a) => 
                    DropdownMenuItem(value: a['id'], child: Text(a['angkot_number']))).toList(),
                  onChanged: (val) => setModalState(() => selectedAngkot = val),
                ),
                
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: () async {
                    if (selectedAngkot == null) return;
                    
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
                    } else {
                      print(response.body);
                      _showSnackBar("Gagal simpan: ${response.statusCode}");
                    }
                  },
                  child: const Text("SIMPAN", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label, 
          prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola Driver"), 
        backgroundColor: const Color(0xFF1A237E), 
        foregroundColor: Colors.white
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchData,
            child: _drivers.isEmpty 
              ? const Center(child: Text("Belum ada data driver"))
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _drivers.length,
                  itemBuilder: (context, index) {
                    final d = _drivers[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
                        title: Text(d['user']['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Plat: ${d['vehicle_plate']} | Angkot: ${d['angkot']['angkot_number']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showForm(driver: d)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteDriver(d['id'])),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00BFA5),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showForm(),
      ),
    );
  }
}