import 'entity.dart';

class Publisher extends Entity<Publisher> {
  @override
  final int id;
  final String name;
  final String city;
  final int foundedYear;
  @override
  final DateTime? deletedAt;

  Publisher({
    required this.id,
    required this.name,
    required this.city,
    required this.foundedYear,
    this.deletedAt,
  });

  Publisher copyWith({
    int? id,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Publisher(
      id: id ?? this.id,
      name: name,
      city: city,
      foundedYear: foundedYear,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  Publisher withId(int id) => copyWith(id: id);

  @override
  Publisher withDeletedAt(DateTime? deletedAt) =>
      copyWith(deletedAt: deletedAt, clearDeletedAt: deletedAt == null);

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'city': city,
    'foundedYear': foundedYear,
  };

  factory Publisher.fromJson(Map<String, dynamic> json) => Publisher(
    id: readInt(json['id']),
    name: readString(json['name']),
    city: readString(json['city']),
    foundedYear: readInt(json['foundedYear']),
    deletedAt: readDate(json['deletedAt']),
  );
}
