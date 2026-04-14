import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────
// Palette (same as LandingPage)
// ─────────────────────────────────────────────
class _P {
  static const b50 = Color(0xFFEFF6FF);
  static const b100 = Color(0xFFDBEAFE);
  static const b200 = Color(0xFFBFDBFE);
  static const b300 = Color(0xFF93C5FD);
  static const b400 = Color(0xFF60A5FA);
  static const b500 = Color(0xFF3B82F6);
  static const b600 = Color(0xFF2563EB);
  static const b700 = Color(0xFF1D4ED8);
  static const b800 = Color(0xFF1E40AF);
  static const bg = Color(0xFFEEF4FF);
  static const card = Colors.white;
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF334155);
  static const ink3 = Color(0xFF64748B);
  static const ink4 = Color(0xFF94A3B8);
  static const dark = Color(0xFF0F2878);
}

class DriverManagementScreen extends StatefulWidget {
  const DriverManagementScreen({super.key});
  @override
  State<DriverManagementScreen> createState() => _DriverManagementScreenState();
}

class _DriverManagementScreenState extends State<DriverManagementScreen>
    with SingleTickerProviderStateMixin {
  // ── Data (unchanged) ─────────────────────────────────────────
  final ApiService _apiService = ApiService();
  List _drivers = [];
  List _filteredDrivers = [];
  List _angkots = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // ── Animation ────────────────────────────────────────────────
  late AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_onSearchChanged);
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  // ── Logic (all unchanged) ─────────────────────────────────────
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
        Uri.parse('${_apiService.baseUrl}/admin/drivers'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final aRes = await http.get(
        Uri.parse('${_apiService.baseUrl}/admin/angkots'),
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
      _showSnackBar(
        'Koneksi bermasalah. Cek server Anda.',
        const Color(0xFFB91C1C),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );
  }

  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _P.card,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hapus Driver?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: _P.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Akun driver $name akan dihapus secara permanen dari sistem.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: _P.ink3,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _P.b50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _P.b100, width: 1.5),
                        ),
                        child: const Center(
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _P.b600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _deleteDriver(id);
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'Hapus',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteDriver(int id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      final res = await http.delete(
        Uri.parse('${_apiService.baseUrl}/admin/drivers/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        _fetchData();
        _showSnackBar('Driver berhasil dihapus', const Color(0xFF16A34A));
      }
    } catch (e) {
      _showSnackBar('Gagal menghapus driver', const Color(0xFFDC2626));
    }
  }

  void _showForm({Map? driver}) {
    final nameCtrl = TextEditingController(text: driver?['user']['name'] ?? '');
    final emailCtrl = TextEditingController(
      text: driver?['user']['email'] ?? '',
    );
    final passCtrl = TextEditingController();
    final plateCtrl = TextEditingController(
      text: driver?['vehicle_plate'] ?? '',
    );
    int? selectedAngkot = driver?['angkot_id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: _P.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _P.b200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              // Title row
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_P.b500, _P.b700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      driver == null
                          ? Icons.person_add_outlined
                          : Icons.edit_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    driver == null
                        ? 'Tambah Personil Baru'
                        : 'Perbarui Data Driver',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: _P.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSheetInput(
                nameCtrl,
                'Nama Lengkap',
                Icons.person_outline_rounded,
              ),
              _buildSheetInput(
                emailCtrl,
                'Email Address',
                Icons.email_outlined,
              ),
              if (driver == null)
                _buildSheetInput(
                  passCtrl,
                  'Password',
                  Icons.lock_outline_rounded,
                  obscure: true,
                ),
              _buildSheetInput(
                plateCtrl,
                'Plat Kendaraan (BK)',
                Icons.directions_bus_outlined,
              ),

              // Dropdown angkot
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _P.b50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _P.b100, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DropdownButtonFormField<int>(
                  value: selectedAngkot,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Armada Angkot',
                    labelStyle: TextStyle(
                      fontSize: 13,
                      color: _P.ink3,
                      fontWeight: FontWeight.w600,
                    ),
                    prefixIcon: Icon(
                      Icons.airport_shuttle_outlined,
                      color: _P.b400,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 4,
                    ),
                  ),
                  items: _angkots
                      .map<DropdownMenuItem<int>>(
                        (a) => DropdownMenuItem(
                          value: a['id'] as int,
                          child: Text(
                            'Angkot ${a['angkot_number']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _P.ink,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => selectedAngkot = val,
                ),
              ),

              const SizedBox(height: 8),
              // Save button
              Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_P.b500, _P.b700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _P.b600.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      if (selectedAngkot == null || nameCtrl.text.isEmpty) {
                        _showSnackBar('Harap lengkapi form', Colors.orange);
                        return;
                      }
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      String? token = prefs.getString('token');
                      final body = {
                        'name': nameCtrl.text,
                        'email': emailCtrl.text,
                        'password': passCtrl.text,
                        'angkot_id': selectedAngkot.toString(),
                        'vehicle_plate': plateCtrl.text,
                      };
                      final url = driver == null
                          ? '${_apiService.baseUrl}/admin/drivers'
                          : '${_apiService.baseUrl}/admin/drivers/${driver['id']}';
                      final response = driver == null
                          ? await http.post(
                              Uri.parse(url),
                              body: body,
                              headers: {
                                'Authorization': 'Bearer $token',
                                'Accept': 'application/json',
                              },
                            )
                          : await http.put(
                              Uri.parse(url),
                              body: body,
                              headers: {
                                'Authorization': 'Bearer $token',
                                'Accept': 'application/json',
                              },
                            );
                      if (response.statusCode == 200) {
                        Navigator.pop(context);
                        _fetchData();
                        _showSnackBar(
                          'Data berhasil disimpan',
                          const Color(0xFF16A34A),
                        );
                      } else {
                        _showSnackBar(
                          'Gagal menyimpan data',
                          const Color(0xFFDC2626),
                        );
                      }
                    },
                    child: const Center(
                      child: Text(
                        'SIMPAN PERUBAHAN',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetInput(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool obscure = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _P.b50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.b100, width: 1.5),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _P.ink,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 13,
            color: _P.ink3,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(icon, color: _P.b400, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 4,
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      body: Stack(
        children: [
          _buildOrbBg(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ── Orb Background ───────────────────────────────────────────
  Widget _buildOrbBg() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _orbCtrl,
          builder: (_, __) {
            final t = _orbCtrl.value;
            return Stack(
              children: [
                Positioned(
                  top: -80 + t * 38,
                  left: -60 + t * 28,
                  child: _orb(300, _P.b400, 0.16),
                ),
                Positioned(
                  top: 180 + t * 28,
                  right: -70 - t * 18,
                  child: _orb(220, const Color(0xFF06B6D4), 0.14),
                ),
                Positioned(
                  bottom: 280 - t * 22,
                  left: 20 + t * 18,
                  child: _orb(180, _P.b300, 0.13),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _orb(double size, Color color, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withOpacity(opacity), Colors.transparent],
      ),
    ),
  );

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_P.b600, _P.b800, _P.dark],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _P.b600.withOpacity(0.30),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Radial overlay
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.85, -0.75),
                    radius: 1.1,
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              // Top row: back + title + count badge
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manajemen Driver',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Total personil: ${_drivers.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_outline_rounded,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${_drivers.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.20),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau plat nomor...',
                    hintStyle: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white60,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _P.b600, strokeWidth: 2.5),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: _P.b600,
      child: _filteredDrivers.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: _filteredDrivers.length,
              itemBuilder: (context, index) =>
                  _buildDriverCard(_filteredDrivers[index]),
            ),
    );
  }

  // ── Driver Card ──────────────────────────────────────────────
  Widget _buildDriverCard(dynamic d) {
    final initial = (d['user']['name'] as String)[0].toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.b100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _P.b500.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_P.b400, _P.b600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d['user']['name'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _P.ink,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _infoBadge(
                      Icons.credit_card_outlined,
                      d['vehicle_plate'],
                      _P.b50,
                      _P.b300,
                      _P.b700,
                    ),
                    _infoBadge(
                      Icons.airport_shuttle_outlined,
                      'Unit ${d['angkot']['angkot_number']}',
                      const Color(0xFFF0FDF4),
                      const Color(0xFF86EFAC),
                      const Color(0xFF15803D),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _actionBtn(
                Icons.edit_outlined,
                const Color(0xFFFFF7ED),
                const Color(0xFFFED7AA),
                const Color(0xFFEA580C),
                () => _showForm(driver: d),
              ),
              const SizedBox(width: 6),
              _actionBtn(
                Icons.delete_outline_rounded,
                const Color(0xFFFEF2F2),
                const Color(0xFFFECACA),
                const Color(0xFFDC2626),
                () =>
                    _confirmDelete(d['id'] as int, d['user']['name'] as String),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(
    IconData icon,
    String label,
    Color bg,
    Color borderColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    Color bg,
    Color borderColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _P.b50,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _P.b100, width: 1.5),
            ),
            child: const Icon(
              Icons.person_off_outlined,
              size: 38,
              color: _P.b300,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Data tidak ditemukan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _P.ink3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Coba ubah kata kunci pencarian',
            style: TextStyle(
              fontSize: 12.5,
              color: _P.ink4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── FAB ──────────────────────────────────────────────────────
  Widget _buildFab() {
    return GestureDetector(
      onTap: () => _showForm(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_P.b500, _P.b700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _P.b600.withOpacity(0.40),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_outlined, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'TAMBAH',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
