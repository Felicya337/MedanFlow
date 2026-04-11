import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiService {
  // final String baseUrl = "http://172.17.65.115:8000/api";
  final String baseUrl = "http://172.17.65.115:8000/api";

  static const String mapboxToken = AppConfig.mapboxToken;
  static const String mapboxTrafficStyle = "mapbox/traffic-day-v2";
  static const String mapboxDarkStyle = "mapbox/dark-v11";

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
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
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

  Future<Map<String, dynamic>> getTravelPrediction(
    double oriLat,
    double oriLng,
    double destLat,
    double destLng,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/predictions/travel-time'),
      headers: {'Accept': 'application/json'},
      body: {
        'origin_lat': oriLat.toString(),
        'origin_lng': oriLng.toString(),
        'dest_lat': destLat.toString(),
        'dest_lng': destLng.toString(),
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Error Prediksi: ${response.body}");
      throw Exception('Gagal mengambil prediksi: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> registerDriver(Map<String, String> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register-driver'),
      body: data,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(jsonDecode(res.body)['message'] ?? 'Gagal Registrasi');
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      body: {'email': email, 'code': code},
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(jsonDecode(res.body)['message'] ?? 'OTP Salah');
  }
}
