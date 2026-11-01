import 'entity.dart';

class Author extends Entity<Author> {
  @override
  final int id;
  final String fullName;
  final String country;
  final int birthYear;
  @override
  final DateTime? deletedAt;

  Author({
    required this.id,
    required this.fullName,
    required this.country,
    required this.birthYear,
    this.deletedAt,
  });

  Author copyWith({int? id, DateTime? deletedAt, bool clearDeletedAt = false}) {
    return Author(
      id: id ?? this.id,
      fullName: fullName,
      country: country,
      birthYear: birthYear,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  Author withId(int id) => copyWith(id: id);

  @override
  Author withDeletedAt(DateTime? deletedAt) =>
      copyWith(deletedAt: deletedAt, clearDeletedAt: deletedAt == null);

  @override
  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'country': country,
    'birthYear': birthYear,
  };

  factory Author.fromJson(Map<String, dynamic> json) => Author(
    id: readInt(json['id']),
    fullName: readString(json['fullName']),
    country: readString(json['country']),
    birthYear: readInt(json['birthYear']),
    deletedAt: readDate(json['deletedAt']),
  );
}
