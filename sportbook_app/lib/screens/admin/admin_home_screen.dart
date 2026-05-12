import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../models/booking.dart';
import '../login_screen.dart';
import 'admin_fields_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String _name = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _name = prefs.getString('name') ?? '');
    final response = await ApiService.get('/admin/bookings');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        _bookings = data.map((e) => Booking.fromJson(e)).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    final response = await ApiService.put('/admin/bookings/$id/status', {'status': status});
    if (response.statusCode == 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status diupdate ke $status!')),
      );
      _loadData();
    }
  }

  Future<void> _deleteBooking(int id) async {
    final response = await ApiService.delete('/admin/bookings/$id');
    if (response.statusCode == 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking berhasil dihapus!')),
      );
      _loadData();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus booking')),
      );
    }
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.green;
      case 'rejected': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return Colors.orange;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'confirmed': return 'Dikonfirmasi';
      case 'rejected': return 'Ditolak';
      case 'cancelled': return 'Dibatalkan';
      default: return 'Menunggu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sports, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFieldsScreen())),
            tooltip: 'Kelola Lapangan',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Halo Admin, $_name! 👋', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Kelola semua booking lapangan di sini.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Semua Booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text('${_bookings.length} Total', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _bookings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('Belum ada booking', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _bookings.length,
                          itemBuilder: (context, index) {
                            final booking = _bookings[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.05), shape: BoxShape.circle),
                                            child: const Icon(Icons.sports, color: Color(0xFF0F172A), size: 18),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            booking.field?['name'] ?? 'Lapangan',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _statusColor(booking.status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _statusText(booking.status),
                                          style: TextStyle(color: _statusColor(booking.status), fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(booking.user?['name'] ?? 'User', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(booking.date, style: TextStyle(color: Colors.grey[700])),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text('${booking.startTime} - ${booking.endTime}', style: TextStyle(color: Colors.grey[700])),
                                    ],
                                  ),
                                  if (booking.status == 'pending') ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _updateStatus(booking.id, 'confirmed'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            child: const Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _updateStatus(booking.id, 'rejected'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red[50],
                                              foregroundColor: Colors.red,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            child: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else if (booking.status == 'confirmed') ...[
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Hapus Booking'),
                                              content: const Text('Apakah Anda yakin ingin menghapus booking ini?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Batal'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _deleteBooking(booking.id);
                                                  },
                                                  child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red[50],
                                          foregroundColor: Colors.red,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: const Text('Hapus Booking', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}