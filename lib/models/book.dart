import 'entity.dart';

class Book extends Entity<Book> {
  @override
  final int id;
  final String title;
  final String isbn;
  final int year;
  final int pages;
  final int publisherId;
  final String publisherName;
  final List<int> authorIds;
  final List<String> authorNames;
  final List<int> genreIds;
  final List<String> genreNames;
  final int copiesTotal;
  final int copiesAvailable;
  @override
  final DateTime? deletedAt;

  Book({
    required this.id,
    required this.title,
    required this.isbn,
    required this.year,
    required this.pages,
    required this.publisherId,
    required this.authorIds,
    required this.genreIds,
    required this.copiesTotal,
    this.copiesAvailable = 0,
    this.publisherName = '',
    this.authorNames = const [],
    this.genreNames = const [],
    this.deletedAt,
  });

  Book copyWith({int? id, DateTime? deletedAt, bool clearDeletedAt = false}) {
    return Book(
      id: id ?? this.id,
      title: title,
      isbn: isbn,
      year: year,
      pages: pages,
      publisherId: publisherId,
      publisherName: publisherName,
      authorIds: authorIds,
      authorNames: authorNames,
      genreIds: genreIds,
      genreNames: genreNames,
      copiesTotal: copiesTotal,
      copiesAvailable: copiesAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  Book withId(int id) => copyWith(id: id);

  @override
  Book withDeletedAt(DateTime? deletedAt) =>
      copyWith(deletedAt: deletedAt, clearDeletedAt: deletedAt == null);

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'isbn': isbn,
    'year': year,
    'pages': pages,
    'publisherId': publisherId,
    'authorIds': authorIds,
    'genreIds': genreIds,
    'copiesTotal': copiesTotal,
  };

  factory Book.fromJson(Map<String, dynamic> json) {
    final publisher = readMap(json['publisher']);
    final authors = readMapList(json['authors']);
    final genres = readMapList(json['genres']);
    return Book(
      id: readInt(json['id']),
      title: readString(json['title']),
      isbn: readString(json['isbn']),
      year: readInt(json['year']),
      pages: readInt(json['pages']),
      publisherId: readInt(json['publisherId'] ?? publisher['id']),
      publisherName: readString(publisher['name']),
      authorIds:
          json['authorIds'] != null
              ? readIntList(json['authorIds'])
              : [for (final a in authors) readInt(a['id'])],
      authorNames: [for (final a in authors) readString(a['fullName'])],
      genreIds:
          json['genreIds'] != null
              ? readIntList(json['genreIds'])
              : [for (final g in genres) readInt(g['id'])],
      genreNames: [for (final g in genres) readString(g['name'])],
      copiesTotal: readInt(json['copiesTotal']),
      copiesAvailable: readInt(json['copiesAvailable']),
      deletedAt: readDate(json['deletedAt']),
    );
  }
}
