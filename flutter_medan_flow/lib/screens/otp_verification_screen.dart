import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});
  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otp = TextEditingController();
  bool _isLoading = false;

  void _verify() async {
    setState(() => _isLoading = true);
    try {
      await ApiService().verifyOtp(widget.email, _otp.text);
      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("Berhasil!"),
      content: const Text("Email diverifikasi. Akun Anda akan aktif setelah disetujui Admin Dishub Medan dalam 1x24 jam."),
      actions: [TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())), child: const Text("OK"))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verifikasi Email")),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Text("Masukkan kode OTP yang dikirim ke ${widget.email}"),
            TextField(controller: _otp, decoration: const InputDecoration(labelText: "Kode OTP"), keyboardType: TextInputType.number),
            const SizedBox(height: 30),
            _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _verify, child: const Text("VERIFIKASI")),
          ],
        ),
      ),
    );
  }
}