import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/author.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../models/reader.dart';
import '../repositories/repository.dart';

class CatalogLookups extends ChangeNotifier {
  final Repository<Author> _authors;
  final Repository<Genre> _genres;
  final Repository<Publisher> _publishers;
  final Repository<Book> _books;
  final Repository<Reader> _readers;

  CatalogLookups(
    this._authors,
    this._genres,
    this._publishers,
    this._books,
    this._readers,
  );

  List<Author> authors = [];
  List<Genre> genres = [];
  List<Publisher> publishers = [];
  List<Book> books = [];
  List<Reader> readers = [];
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (!_loaded) await reload();
  }

  Future<void> reload() async {
    try {
      authors = await _authors.findAll();
      genres = await _genres.findAll();
      publishers = await _publishers.findAll();
      _loaded = true;
    } on ApiException {
      _loaded = false;
    }
    notifyListeners();
  }

  Future<void> loadLoanOptions() async {
    try {
      books = await _books.findAll();
      readers = await _readers.findAll();
    } on ApiException {
      books = [];
      readers = [];
    }
    notifyListeners();
  }

  List<Author> get activeAuthors => authors.where((a) => !a.isDeleted).toList();
  List<Genre> get activeGenres => genres.where((g) => !g.isDeleted).toList();
  List<Publisher> get activePublishers =>
      publishers.where((p) => !p.isDeleted).toList();
}
