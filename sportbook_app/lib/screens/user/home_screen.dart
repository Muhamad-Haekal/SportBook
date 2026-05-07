import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../models/field.dart';
import 'field_detail_screen.dart';
import 'my_bookings_screen.dart';
import '../login_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Field> _fields = [];
  List<Field> _filteredFields = [];
  bool _isLoading = true;
  String _name = '';
  String _selectedCategory = 'Semua';
  final _searchController = TextEditingController();

  final List<String> _categories = ['Semua', 'Futsal', 'Badminton', 'Basket', 'Tenis', 'Voli'];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterFields);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _name = prefs.getString('name') ?? '');

    final response = await ApiService.get('/fields');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        _fields = data.map((e) => Field.fromJson(e)).toList();
        _filteredFields = _fields;
        _isLoading = false;
      });
    }
  }

  void _filterFields() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFields = _fields.where((field) {
        final matchSearch = field.name.toLowerCase().contains(query) ||
            field.type.toLowerCase().contains(query) ||
            field.description.toLowerCase().contains(query);
        final matchCategory = _selectedCategory == 'Semua' ||
            field.type.toLowerCase() == _selectedCategory.toLowerCase();
        return matchSearch && matchCategory;
      }).toList();
    });
  }

  void _selectCategory(String category) {
    setState(() => _selectedCategory = category);
    _filterFields();
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        elevation: 0,
        title: const Text('SportBook', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF059669),
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Halo, $_name! 👋', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Mau olahraga apa hari ini?', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari lapangan favoritmu...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF059669)),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterFields();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => _selectCategory(cat),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)])
                                  : null,
                              color: isSelected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                if (!isSelected) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                                if (isSelected) BoxShadow(color: const Color(0xFF059669).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                              border: isSelected ? null : Border.all(color: Colors.grey[200]!),
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey[700],
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pilih Lapangan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('${_filteredFields.length} lapangan', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredFields.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text('Lapangan tidak ditemukan', style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredFields.length,
                          itemBuilder: (context, index) {
                            final field = _filteredFields[index];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => FieldDetailScreen(field: field)),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        if (field.photo.isNotEmpty)
                                          Image.network(
                                            '${ApiService.baseUrl}${field.photo}',
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              height: 180,
                                              color: Colors.grey[100],
                                              child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[300]),
                                            ),
                                          )
                                        else
                                          Container(
                                            height: 180,
                                            color: Colors.grey[100],
                                            child: Icon(Icons.sports, size: 50, color: Colors.grey[300]),
                                          ),
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(field.type, style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 12)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(field.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                                const SizedBox(height: 6),
                                                Text(
                                                  field.pricePerHour > 0
                                                      ? 'Rp ${_formatPrice(field.pricePerHour)} / jam'
                                                      : 'Hubungi Admin',
                                                  style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w600, fontSize: 14),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF059669).withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.arrow_forward_ios, color: Color(0xFF059669), size: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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