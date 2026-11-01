import 'entity.dart';

class LibraryCard {
  final String number;
  final DateTime? issuedAt;
  final DateTime? expiresAt;

  const LibraryCard({required this.number, this.issuedAt, this.expiresAt});

  bool get isActive => expiresAt != null && expiresAt!.isAfter(DateTime.now());

  factory LibraryCard.fromJson(Map<String, dynamic> json) => LibraryCard(
    number: readString(json['number']),
    issuedAt: readDate(json['issuedAt']),
    expiresAt: readDate(json['expiresAt']),
  );
}

class Reader extends Entity<Reader> {
  @override
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final LibraryCard? card;
  @override
  final DateTime? deletedAt;

  Reader({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.card,
    this.deletedAt,
  });

  Reader copyWith({int? id, DateTime? deletedAt, bool clearDeletedAt = false}) {
    return Reader(
      id: id ?? this.id,
      fullName: fullName,
      email: email,
      phone: phone,
      card: card,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  Reader withId(int id) => copyWith(id: id);

  @override
  Reader withDeletedAt(DateTime? deletedAt) =>
      copyWith(deletedAt: deletedAt, clearDeletedAt: deletedAt == null);

  @override
  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
  };

  factory Reader.fromJson(Map<String, dynamic> json) {
    final card = readMap(json['card']);
    return Reader(
      id: readInt(json['id']),
      fullName: readString(json['fullName']),
      email: readString(json['email']),
      phone: readString(json['phone']),
      card: card.isEmpty ? null : LibraryCard.fromJson(card),
      deletedAt: readDate(json['deletedAt']),
    );
  }
}
