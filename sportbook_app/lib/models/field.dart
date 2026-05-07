class Field {
  final int id;
  final String name;
  final String type;
  final String description;
  final String photo;
  final int pricePerHour;
  final String openTime;
  final String closeTime;
  final bool isClosed;
  final String locationLink;

  Field({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.photo,
    required this.pricePerHour,
    required this.openTime,
    required this.closeTime,
    this.isClosed = false,
    required this.locationLink,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      id: json['ID'],
      name: json['name'],
      type: json['type'],
      description: json['description'],
      photo: json['photo'],
      pricePerHour: json['price_per_hour'] ?? 0,
      openTime: (json['open_time'] == null || json['open_time'] == '') ? '07:00' : json['open_time'],
      closeTime: (json['close_time'] == null || json['close_time'] == '') ? '22:00' : json['close_time'],
      isClosed: json['is_closed'] ?? false,
      locationLink: json['location_link'] ?? '',
    );
  }
}