class Booking {
  final int id;
  final int userId;
  final int fieldId;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final int totalPrice;
  final Map<String, dynamic>? field;
  final Map<String, dynamic>? user;

  Booking({
    required this.id,
    required this.userId,
    required this.fieldId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.totalPrice,
    this.field,
    this.user,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['ID'],
      userId: json['user_id'],
      fieldId: json['field_id'],
      date: json['date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      status: json['status'],
      paymentMethod: json['payment_method'] ?? 'cash',
      paymentStatus: json['payment_status'] ?? 'unpaid',
      totalPrice: json['total_price'] ?? 0,
      field: json['field'],
      user: json['user'],
    );
  }
}