import 'entity.dart';

class Loan extends Entity<Loan> {
  @override
  final int id;
  final int readerId;
  final String readerName;
  final int bookId;
  final String bookTitle;
  final DateTime? issuedAt;
  final DateTime? dueAt;
  final DateTime? returnedAt;
  final String status;
  final int days;
  @override
  final DateTime? deletedAt;

  Loan({
    required this.id,
    required this.readerId,
    required this.bookId,
    this.readerName = '',
    this.bookTitle = '',
    this.issuedAt,
    this.dueAt,
    this.returnedAt,
    this.status = 'active',
    this.days = 14,
    this.deletedAt,
  });

  bool get isReturned => status == 'returned';

  String get statusLabel => switch (status) {
    'returned' => 'возвращена',
    'overdue' => 'просрочена',
    _ => 'активна',
  };

  Loan copyWith({int? id, DateTime? deletedAt, bool clearDeletedAt = false}) {
    return Loan(
      id: id ?? this.id,
      readerId: readerId,
      readerName: readerName,
      bookId: bookId,
      bookTitle: bookTitle,
      issuedAt: issuedAt,
      dueAt: dueAt,
      returnedAt: returnedAt,
      status: status,
      days: days,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  Loan withId(int id) => copyWith(id: id);

  @override
  Loan withDeletedAt(DateTime? deletedAt) =>
      copyWith(deletedAt: deletedAt, clearDeletedAt: deletedAt == null);

  @override
  Map<String, dynamic> toJson() => {
    'readerId': readerId,
    'bookId': bookId,
    'days': days,
  };

  factory Loan.fromJson(Map<String, dynamic> json) {
    final reader = readMap(json['reader']);
    final book = readMap(json['book']);
    return Loan(
      id: readInt(json['id']),
      readerId: readInt(json['readerId'] ?? reader['id']),
      readerName: readString(reader['fullName']),
      bookId: readInt(json['bookId'] ?? book['id']),
      bookTitle: readString(book['title']),
      issuedAt: readDate(json['issuedAt']),
      dueAt: readDate(json['dueAt']),
      returnedAt: readDate(json['returnedAt']),
      status: readString(json['status'], 'active'),
      deletedAt: readDate(json['deletedAt']),
    );
  }
}
