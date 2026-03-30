import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = "http://172.17.65.115:8000/api"; // GANTI IP ANDA

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setInt('role_id', data['user']['role_id']);
      return data;
    } else {
      throw Exception('Login Gagal: Cek kembali akun Anda');
    }
  }

  Future<int> startTrip() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    
    final response = await http.post(
      Uri.parse('$baseUrl/trips/start'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['id'];
    } else {
      // DEBUG: Cetak isi error dari server agar tahu penyebabnya
      print("Server Error: ${response.body}"); 
      throw Exception('Gagal memulai perjalanan: ${response.statusCode}');
    }
  }

  Future<void> updateLocation(
    int tripId,
    double lat,
    double lng,
    double speed,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    await http.post(
      Uri.parse('$baseUrl/trips/$tripId/location'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      body: {
        'latitude': lat.toString(),
        'longitude': lng.toString(),
        'speed': speed.toString(),
      },
    );
  }

  Future<List<dynamic>> getActiveAngkots() async {
    final response = await http.get(Uri.parse('$baseUrl/trips/active'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Gagal mengambil data angkot');
  }

  // Fungsi Baru: Ambil Notifikasi Cerdas
  Future<Map<String, dynamic>> getNotifications() async {
    final response = await http.get(Uri.parse('$baseUrl/notifications'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Gagal mengambil notifikasi');
  }
}
