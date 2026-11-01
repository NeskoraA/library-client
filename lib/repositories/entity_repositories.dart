import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/author.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/loan.dart';
import '../models/publisher.dart';
import '../models/reader.dart';
import 'api_repository.dart';

class BookRepository extends ApiRepository<Book> {
  BookRepository(Dio dio) : super(dio, '/books');

  @override
  Book fromJson(Map<String, dynamic> json) => Book.fromJson(json);
}

class AuthorRepository extends ApiRepository<Author> {
  AuthorRepository(Dio dio) : super(dio, '/authors');

  @override
  Author fromJson(Map<String, dynamic> json) => Author.fromJson(json);
}

class GenreRepository extends ApiRepository<Genre> {
  GenreRepository(Dio dio) : super(dio, '/genres');

  @override
  Genre fromJson(Map<String, dynamic> json) => Genre.fromJson(json);
}

class PublisherRepository extends ApiRepository<Publisher> {
  PublisherRepository(Dio dio) : super(dio, '/publishers');

  @override
  Publisher fromJson(Map<String, dynamic> json) => Publisher.fromJson(json);
}

class ReaderRepository extends ApiRepository<Reader> {
  ReaderRepository(Dio dio) : super(dio, '/readers');

  @override
  Reader fromJson(Map<String, dynamic> json) => Reader.fromJson(json);
}

class LoanRepository extends ApiRepository<Loan> {
  LoanRepository(Dio dio) : super(dio, '/loans');

  @override
  Loan fromJson(Map<String, dynamic> json) => Loan.fromJson(json);

  Future<void> returnLoan(int id) => guard(() => dio.post('$path/$id/return'));
}
