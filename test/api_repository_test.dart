import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/core/api_client.dart';
import 'package:library_app/core/api_exceptions.dart';
import 'package:library_app/models/book.dart';
import 'package:library_app/models/list_query.dart';
import 'package:library_app/repositories/entity_repositories.dart';

class FakeAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json; charset=utf-8'],
  },
);

final bookJson = {
  'id': 1,
  'title': 'Война и мир',
  'isbn': '978-5-17-118366-4',
  'year': 1869,
  'pages': 1300,
  'publisher': {'id': 1, 'name': 'АСТ'},
  'authors': [
    {'id': 1, 'fullName': 'Толстой Л. Н.'},
  ],
  'genres': [
    {'id': 2, 'name': 'Роман'},
  ],
  'copiesTotal': 4,
  'copiesAvailable': 2,
  'deletedAt': null,
};

(BookRepository, FakeAdapter) setup(
  ResponseBody Function(RequestOptions) handler,
) {
  final dio = buildDio(retryDelay: Duration.zero);
  final adapter = FakeAdapter(handler);
  dio.httpClientAdapter = adapter;
  return (BookRepository(dio), adapter);
}

void main() {
  const query = ListQuery(
    path: '/books',
    defaultSort: 'title',
    search: 'война',
    filters: {'genreId': '2'},
    sortField: 'year',
    sortAscending: false,
    page: 2,
  );

  test(
    'список разбирается из оболочки ответа и параметры уходят на сервер',
    () async {
      final (repo, adapter) = setup(
        (_) => json(200, {
          'items': [bookJson],
          'page': 2,
          'size': 10,
          'total': 11,
          'totalPages': 2,
        }),
      );
      final page = await repo.find(query);
      expect(page.items.single.title, 'Война и мир');
      expect(page.total, 11);
      expect(page.page, 2);
      final params = adapter.requests.single.queryParameters;
      expect(params['search'], 'война');
      expect(params['genreId'], '2');
      expect(params['sort'], 'year,desc');
      expect(params['page'], 2);
    },
  );

  test('книга разбирает развёрнутые объекты из ответа', () {
    final book = Book.fromJson(bookJson);
    expect(book.publisherId, 1);
    expect(book.publisherName, 'АСТ');
    expect(book.authorIds, [1]);
    expect(book.genreNames, ['Роман']);
    expect(book.toJson()['genreIds'], [2]);
  });

  test(
    'ответ 422 превращается в ValidationException с ошибками по полям',
    () async {
      final (repo, _) = setup(
        (_) => json(422, {
          'message': 'Ошибка валидации',
          'errors': {'isbn': 'Книга с таким ISBN уже существует'},
        }),
      );
      await expectLater(
        repo.create(Book.fromJson(bookJson)),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.errors['isbn'],
            'isbn',
            'Книга с таким ISBN уже существует',
          ),
        ),
      );
    },
  );

  test('ответ 409 превращается в ConflictException', () async {
    final (repo, _) = setup(
      (_) => json(409, {'message': 'Книга выдана и не может быть удалена'}),
    );
    await expectLater(
      repo.hardDelete(1),
      throwsA(
        isA<ConflictException>().having(
          (e) => e.message,
          'message',
          'Книга выдана и не может быть удалена',
        ),
      ),
    );
  });

  test('404 при запросе одной записи возвращает null', () async {
    final (repo, _) = setup((_) => json(404, {'message': 'Объект не найден'}));
    expect(await repo.findById(99), isNull);
  });

  test('ответ 500 превращается в ServerException', () async {
    final (repo, _) = setup((_) => json(500, {'message': 'Сбой'}));
    await expectLater(repo.find(query), throwsA(isA<ServerException>()));
  });

  test(
    'недоступный сервер даёт NetworkException после трёх попыток чтения',
    () async {
      final (repo, adapter) = setup(
        (o) =>
            throw DioException.connectionError(
              requestOptions: o,
              reason: 'connection refused',
            ),
      );
      await expectLater(repo.find(query), throwsA(isA<NetworkException>()));
      expect(adapter.requests.length, 3);
    },
  );

  test('создание записи при сетевом сбое не повторяется', () async {
    final (repo, adapter) = setup(
      (o) =>
          throw DioException.connectionError(
            requestOptions: o,
            reason: 'connection refused',
          ),
    );
    await expectLater(
      repo.create(Book.fromJson(bookJson)),
      throwsA(isA<NetworkException>()),
    );
    expect(adapter.requests.length, 1);
  });
}
