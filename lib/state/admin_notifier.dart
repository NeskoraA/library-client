import '../models/app_user.dart';
import '../models/book.dart';
import '../models/loan.dart';
import '../models/reader.dart';
import '../repositories/auth_repository.dart';
import '../repositories/repository.dart';

class LibraryStats {
  final int books;
  final int readers;
  final int activeLoans;
  final int overdueLoans;
  final int returnedLoans;

  const LibraryStats(
    this.books,
    this.readers,
    this.activeLoans,
    this.overdueLoans,
    this.returnedLoans,
  );
}

class AdminNotifier {
  final AuthRepository _auth;
  final Repository<Book> _books;
  final Repository<Reader> _readers;
  final Repository<Loan> _loans;

  AdminNotifier(this._auth, this._books, this._readers, this._loans);

  Future<List<AppUser>> users() => _auth.users();

  Future<LibraryStats> stats() async => LibraryStats(
    await _books.count({}),
    await _readers.count({}),
    await _loans.count({'status': 'active'}),
    await _loans.count({'status': 'overdue'}),
    await _loans.count({'status': 'returned'}),
  );
}
