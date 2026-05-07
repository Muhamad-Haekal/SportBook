import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/field.dart';
import '../../services/api_service.dart';

class BookingScreen extends StatefulWidget {
  final Field field;
  const BookingScreen({super.key, required this.field});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _dateController = TextEditingController();
  String? _selectedStartTime;
  String? _selectedEndTime;
  String _paymentMethod = 'cash';
  bool _isLoading = false;
  int _totalPrice = 0;
  List<Map<String, String>> _bookedRanges = [];
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDate(DateTime.now());
    _fetchBookedSlots();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookedSlots() async {
    if (_dateController.text.isEmpty) return;
    setState(() {
      _isLoadingSlots = true;
      _selectedStartTime = null;
      _selectedEndTime = null;
      _totalPrice = 0;
    });

    try {
      final response = await ApiService.get('/fields/${widget.field.id}/bookings?date=${_dateController.text}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _bookedRanges = data.map((b) => {
            'start': b['start_time'].toString(),
            'end': b['end_time'].toString(),
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching booked slots: $e');
    } finally {
      setState(() {
        _isLoadingSlots = false;
      });
    }
  }

  List<String> _generateTimeSlots() {
    final slots = <String>[];
    final openT = widget.field.openTime.isNotEmpty ? widget.field.openTime : '07:00';
    final closeT = widget.field.closeTime.isNotEmpty ? widget.field.closeTime : '22:00';
    
    final openParts = openT.split(':');
    final closeParts = closeT.split(':');
    
    int openHour = int.tryParse(openParts[0]) ?? 7;
    int closeHour = int.tryParse(closeParts[0]) ?? 22;
    
    for (int h = openHour; h <= closeHour; h++) {
      slots.add('${h.toString().padLeft(2, '0')}:00');
    }
    return slots;
  }

  void _calculatePrice() {
    if (_selectedStartTime == null || _selectedEndTime == null) return;
    final startParts = _selectedStartTime!.split(':');
    final endParts = _selectedEndTime!.split(':');
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    final totalMinutes = endMinutes - startMinutes;
    if (totalMinutes <= 0) {
      setState(() => _totalPrice = 0);
      return;
    }
    int hours = totalMinutes ~/ 60;
    if (totalMinutes % 60 > 0) hours++;
    setState(() => _totalPrice = widget.field.pricePerHour * hours);
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = _formatDate(picked);
      });
      _fetchBookedSlots();
    }
  }

  void _showQrisDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.qr_code, color: Colors.blue[700]),
            const SizedBox(width: 8),
            const Text('Bayar via QRIS', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Total Tagihan', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_formatPrice(_totalPrice)}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/qris.jpg', width: 220, height: 220, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            const Text(
              'Scan QRIS menggunakan Dana\natau e-wallet lainnya',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: const Text(
                '⚠️ Setelah bayar, booking akan dikonfirmasi admin',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.orange),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitBooking();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            child: const Text('Sudah Bayar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBooking() async {
    setState(() => _isLoading = true);
    final response = await ApiService.post('/bookings', {
      'field_id': widget.field.id,
      'date': _dateController.text,
      'start_time': _selectedStartTime,
      'end_time': _selectedEndTime,
      'payment_method': _paymentMethod,
    });
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking berhasil! Menunggu konfirmasi admin'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
      Navigator.pop(context);
    } else if (response.statusCode == 409) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lapangan sudah dibooking pada jam tersebut!'), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking gagal!')),
      );
    }
  }

  Future<void> _booking() async {
    if (_dateController.text.isEmpty || _selectedStartTime == null || _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua data!')),
      );
      return;
    }
    if (_paymentMethod == 'qris') {
      _showQrisDialog();
    } else {
      _submitBooking();
    }
  }

  Widget _timeSlotWidget(String time, bool isSelected, bool isDisabled, VoidCallback? onTap) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey[100] : isSelected ? const Color(0xFF059669) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled ? Colors.grey[200]! : isSelected ? const Color(0xFF059669) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected) BoxShadow(color: const Color(0xFF059669).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
            if (!isDisabled && !isSelected) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isDisabled ? Colors.grey[400] : isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeSlots = _generateTimeSlots();
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        elevation: 0,
        title: const Text('Booking Lapangan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info lapangan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sports, color: Color(0xFF059669)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.field.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(widget.field.type, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('Rp ${_formatPrice(widget.field.pricePerHour)} / jam',
                            style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${widget.field.openTime} - ${widget.field.closeTime}',
                            style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tanggal
            TextField(
              controller: _dateController,
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                labelText: 'Tanggal',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Jam Mulai
            const Text('Jam Mulai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            if (_isLoadingSlots)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: timeSlots.map((time) {
                  final isSelected = _selectedStartTime == time;
                  
                  // Check if this time falls within any booked range (time >= start && time < end)
                  bool isBooked = _bookedRanges.any((range) => time.compareTo(range['start']!) >= 0 && time.compareTo(range['end']!) < 0);
                  
                  final isDisabled = isBooked || (_selectedEndTime != null && time.compareTo(_selectedEndTime!) >= 0);
                  
                  return _timeSlotWidget(time, isSelected, isDisabled, () {
                    setState(() {
                      _selectedStartTime = time;
                      if (_selectedEndTime != null && _selectedEndTime!.compareTo(time) <= 0) {
                        _selectedEndTime = null;
                        _totalPrice = 0;
                      }
                      // If there is a booked slot between start and end, reset end time
                      if (_selectedEndTime != null) {
                        bool hasConflict = _bookedRanges.any((range) => 
                            _selectedStartTime!.compareTo(range['end']!) < 0 && _selectedEndTime!.compareTo(range['start']!) > 0);
                        if (hasConflict) {
                          _selectedEndTime = null;
                          _totalPrice = 0;
                        }
                      }
                    });
                    _calculatePrice();
                  });
                }).toList(),
              ),
            const SizedBox(height: 20),

            // Jam Selesai
            const Text('Jam Selesai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            if (_isLoadingSlots)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: timeSlots.map((time) {
                  final isSelected = _selectedEndTime == time;
                  
                  // Check if this time is the start of a booked slot (can be end time if start time is before)
                  // Wait, time is end time. We cannot select end time <= start time
                  bool isBeforeStart = _selectedStartTime == null || time.compareTo(_selectedStartTime!) <= 0;
                  
                  // Check if there is any booking between selectedStartTime and this time
                  bool hasConflict = false;
                  if (_selectedStartTime != null && !isBeforeStart) {
                     hasConflict = _bookedRanges.any((range) => 
                        _selectedStartTime!.compareTo(range['end']!) < 0 && time.compareTo(range['start']!) > 0);
                  }
                  
                  final isDisabled = isBeforeStart || hasConflict;
                  
                  return _timeSlotWidget(time, isSelected, isDisabled, () {
                    setState(() => _selectedEndTime = time);
                    _calculatePrice();
                  });
                }).toList(),
              ),
            const SizedBox(height: 20),

            // Total harga
            if (_totalPrice > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: const Color(0xFF059669).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Pembayaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('$_selectedStartTime - $_selectedEndTime',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                      ],
                    ),
                    Text('Rp ${_formatPrice(_totalPrice)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Metode pembayaran
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _paymentMethod = 'cash'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _paymentMethod == 'cash' ? const Color(0xFF059669).withOpacity(0.05) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _paymentMethod == 'cash' ? const Color(0xFF059669) : Colors.grey[200]!,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.money, size: 32,
                                      color: _paymentMethod == 'cash' ? const Color(0xFF059669) : Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text('Cash', style: TextStyle(fontWeight: FontWeight.bold,
                                      color: _paymentMethod == 'cash' ? const Color(0xFF059669) : Colors.grey[600])),
                                  const SizedBox(height: 4),
                                  Text('Bayar di lapangan', textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _paymentMethod = 'qris'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _paymentMethod == 'qris' ? Colors.blue.withOpacity(0.05) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _paymentMethod == 'qris' ? Colors.blue[600]! : Colors.grey[200]!,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.qr_code, size: 32,
                                      color: _paymentMethod == 'qris' ? Colors.blue[600] : Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text('QRIS', style: TextStyle(fontWeight: FontWeight.bold,
                                      color: _paymentMethod == 'qris' ? Colors.blue[600] : Colors.grey[600])),
                                  const SizedBox(height: 4),
                                  Text('Dana / e-wallet', textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _booking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Konfirmasi Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}