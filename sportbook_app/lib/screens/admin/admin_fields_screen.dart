import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import '../../models/field.dart';

class AdminFieldsScreen extends StatefulWidget {
  const AdminFieldsScreen({super.key});

  @override
  State<AdminFieldsScreen> createState() => _AdminFieldsScreenState();
}

class _AdminFieldsScreenState extends State<AdminFieldsScreen> {
  List<Field> _fields = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    final response = await ApiService.get('/fields');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        _fields = data.map((e) => Field.fromJson(e)).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteField(int id) async {
    final response = await ApiService.delete('/admin/fields/$id');
    if (response.statusCode == 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lapangan dihapus!')),
      );
      _loadFields();
    }
  }

  Future<void> _toggleFieldStatus(Field field, bool isClosed) async {
    final body = {
      'name': field.name,
      'type': field.type,
      'description': field.description,
      'photo': field.photo,
      'price_per_hour': field.pricePerHour,
      'open_time': field.openTime,
      'close_time': field.closeTime,
      'is_closed': isClosed,
      'location_link': field.locationLink,
    };
    final response = await ApiService.put('/admin/fields/${field.id}', body);
    if (response.statusCode == 200) {
      _loadFields();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isClosed ? 'Lapangan ditutup!' : 'Lapangan dibuka!')),
      );
    }
  }

  Future<String?> _uploadPhoto(Uint8List bytes, String filename) async {
    final token = await ApiService.getToken();
    final uri = Uri.parse('${ApiService.baseUrl}/admin/upload');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes('photo', bytes, filename: filename));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final data = jsonDecode(body);
      return data['url'];
    }
    return null;
  }

  void _showFieldDialog({Field? field}) {
    final nameController = TextEditingController(text: field?.name ?? '');
    final typeController = TextEditingController(text: field?.type ?? '');
    final descController = TextEditingController(text: field?.description ?? '');
    final priceController = TextEditingController(
        text: field != null && field.pricePerHour > 0 ? field.pricePerHour.toString() : '');
    final openTimeController = TextEditingController(text: field?.openTime ?? '07:00');
    final closeTimeController = TextEditingController(text: field?.closeTime ?? '22:00');
    final locationLinkController = TextEditingController(text: field?.locationLink ?? '');
    String? photoUrl = field?.photo;
    Uint8List? selectedBytes;
    String? selectedFilename;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(field == null ? 'Tambah Lapangan' : 'Edit Lapangan',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Lapangan',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: typeController,
                    decoration: InputDecoration(
                      labelText: 'Jenis (Futsal, Badminton, dll)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationLinkController,
                    decoration: InputDecoration(
                      labelText: 'Link Lokasi (Google Maps dll)',
                      hintText: 'https://...',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Harga per Jam (Rp)',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Jam Operasional', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: openTimeController,
                          decoration: InputDecoration(
                            labelText: 'Jam Buka',
                            hintText: '07:00',
                            prefixIcon: const Icon(Icons.access_time),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: closeTimeController,
                          decoration: InputDecoration(
                            labelText: 'Jam Tutup',
                            hintText: '22:00',
                            prefixIcon: const Icon(Icons.access_time_filled),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Foto Lapangan', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        withData: true,
                      );
                      if (result != null && result.files.first.bytes != null) {
                        setStateDialog(() {
                          selectedBytes = result.files.first.bytes;
                          selectedFilename = result.files.first.name;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[300]!, width: 2),
                      ),
                      child: selectedBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(selectedBytes!, fit: BoxFit.contain),
                            )
                          : photoUrl != null && photoUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    '${ApiService.baseUrl}$photoUrl',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => _uploadPlaceholder(),
                                  ),
                                )
                              : _uploadPlaceholder(),
                    ),
                  ),
                  if (selectedFilename != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('📎 $selectedFilename',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      setStateDialog(() => isUploading = true);
                      String finalPhoto = photoUrl ?? '';
                      if (selectedBytes != null && selectedFilename != null) {
                        final url = await _uploadPhoto(selectedBytes!, selectedFilename!);
                        if (url != null) finalPhoto = url;
                      }
                      final body = {
                        'name': nameController.text,
                        'type': typeController.text,
                        'description': descController.text,
                        'photo': finalPhoto,
                        'price_per_hour': int.tryParse(priceController.text) ?? 0,
                        'open_time': openTimeController.text,
                        'close_time': closeTimeController.text,
                        'is_closed': field?.isClosed ?? false,
                        'location_link': locationLinkController.text,
                      };
                      if (field == null) {
                        await ApiService.post('/admin/fields', body);
                      } else {
                        await ApiService.put('/admin/fields/${field.id}', body);
                      }
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _loadFields();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isUploading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(field == null ? 'Tambah' : 'Simpan',
                      style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadPlaceholder() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, size: 48, color: const Color(0xFF0F172A).withOpacity(0.5)),
          const SizedBox(height: 8),
          Text('Klik untuk pilih foto', style: TextStyle(color: const Color(0xFF0F172A).withOpacity(0.7))),
        ],
      ),
    );
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
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Kelola Lapangan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F172A),
        onPressed: () => _showFieldDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
          : _fields.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_soccer, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Belum ada lapangan', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _fields.length,
                  itemBuilder: (context, index) {
                    final field = _fields[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (field.photo.isNotEmpty)
                            Image.network(
                              '${ApiService.baseUrl}${field.photo}',
                              width: double.infinity,
                              height: 180,
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
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(field.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    Row(
                                      children: [
                                        if (field.isClosed)
                                          Container(
                                            margin: const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                            child: const Text('Tutup', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F172A).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(field.type, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(field.description, style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Rp ${_formatPrice(field.pricePerHour)} / jam', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text('${field.openTime} - ${field.closeTime}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                     Row(
                                      children: [
                                        Column(
                                          children: [
                                            Switch(
                                              value: !field.isClosed,
                                              onChanged: (val) => _toggleFieldStatus(field, !val),
                                              activeColor: Colors.green,
                                            ),
                                            Text(field.isClosed ? 'Tutup' : 'Buka', style: TextStyle(fontSize: 10, color: field.isClosed ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF0F172A)),
                                          onPressed: () => _showFieldDialog(field: field),
                                          style: IconButton.styleFrom(backgroundColor: const Color(0xFF0F172A).withOpacity(0.05)),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () => _deleteField(field.id),
                                          style: IconButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.05)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}