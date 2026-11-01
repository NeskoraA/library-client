abstract class Entity<T extends Entity<T>> {
  int get id;
  DateTime? get deletedAt;

  bool get isDeleted => deletedAt != null;

  T withId(int id);
  T withDeletedAt(DateTime? deletedAt);
  Map<String, dynamic> toJson();
}

int readInt(Object? value, [int fallback = 0]) => switch (value) {
  int v => v,
  num v => v.toInt(),
  String v => int.tryParse(v) ?? fallback,
  _ => fallback,
};

String readString(Object? value, [String fallback = '']) =>
    value is String ? value : fallback;

List<int> readIntList(Object? value) =>
    value is List
        ? value.map((e) => readInt(e, -1)).where((e) => e >= 0).toList()
        : <int>[];

DateTime? readDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

Map<String, dynamic> readMap(Object? value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};

List<Map<String, dynamic>> readMapList(Object? value) =>
    value is List ? value.whereType<Map<String, dynamic>>().toList() : [];
