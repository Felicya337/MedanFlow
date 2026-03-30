import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'driver_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  void _login() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().login(_email.text, _pass.text);
      if (res['user']['role_id'] == 2) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverHomeScreen()));
      } else {
        // Logika untuk Admin/Guest lainnya
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Berhasil!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Masuk ke Medan Flow")),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const Text("Silakan masuk menggunakan akun pemerintah atau driver yang sudah terdaftar.", 
              style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            TextField(controller: _email, decoration: const InputDecoration(labelText: "Email Address", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder())),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _loading 
                ? const Center(child: CircularProgressIndicator()) 
                : ElevatedButton(onPressed: _login, child: const Text("LOGIN")),
            )
          ],
        ),
      ),
    );
  }
}