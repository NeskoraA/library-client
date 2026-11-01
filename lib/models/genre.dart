import 'entity.dart';

class Genre extends Entity<Genre> {
  @override
  final int id;
  final String name;
  final String description;
  @override
  final DateTime? deletedAt;

  Genre({
    required this.id,
    required this.name,
    this.description = '',
    this.deletedAt,
  });

  Genre copyWith({int? id, DateTime? deletedAt, bool clearDeletedAt = false}) {
    return Genre(
      id: id ?? this.id,
      name: name,
      description: description,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  Genre withId(int id) => copyWith(id: id);

  @override
  Genre withDeletedAt(DateTime? deletedAt) =>
      copyWith(deletedAt: deletedAt, clearDeletedAt: deletedAt == null);

  @override
  Map<String, dynamic> toJson() => {'name': name, 'description': description};

  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
    id: readInt(json['id']),
    name: readString(json['name']),
    description: readString(json['description']),
    deletedAt: readDate(json['deletedAt']),
  );
}
