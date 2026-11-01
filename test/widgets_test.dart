import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:library_app/core/api_client.dart';
import 'package:library_app/main.dart';
import 'package:library_app/repositories/auth_repository.dart';
import 'package:library_app/state/auth_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeServer implements HttpClientAdapter {
  bool down = false;
  int? failStatus;
  Completer<void>? gate;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async {
    if (down) {
      throw DioException.connectionError(requestOptions: o, reason: 'refused');
    }
    if (gate != null) await gate!.future;

    ResponseBody reply(int status, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
    Map<String, Object> page(List<Object> items) => {
      'items': items,
      'page': 1,
      'size': 10,
      'total': items.length,
      'totalPages': 1,
    };

    if (o.path == '/books') {
      if (failStatus != null) return reply(failStatus!, {'message': 'Сбой'});
      if (o.queryParameters['search'] == 'zzz') return reply(200, page([]));
      return reply(
        200,
        page([
          {
            'id': 1,
            'title':
                'Очень длинное название книги, которое не должно ломать '
                'раскладку приложения на узком экране телефона',
            'isbn': '978-5-17-118366-4',
            'year': 1869,
            'pages': 1300,
            'publisher': {'id': 1, 'name': 'АСТ'},
            'authors': <Object>[],
            'genres': <Object>[],
            'copiesTotal': 1,
            'copiesAvailable': 1,
          },
        ]),
      );
    }
    return reply(200, page([]));
  }

  @override
  void close({bool force = false}) {}
}

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 4; i++) {
    await t.pump(const Duration(milliseconds: 200));
  }
}

Future<GoRouter> start(
  WidgetTester t,
  FakeServer server, {
  String role = 'librarian',
  Size size = const Size(1280, 900),
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  SharedPreferences.setMockInitialValues({
    'auth_access_token': 'a.b',
    'auth_refresh_token': 'r.t',
    'auth_role': role,
    'auth_full_name': 'Тестовый Т. Т.',
    'auth_login_at': DateTime.now().millisecondsSinceEpoch,
  });
  final prefs = await SharedPreferences.getInstance();
  final auth = AuthNotifier(prefs);
  final dio = buildDio(
    tokenProvider: () => auth.accessToken,
    retryDelay: Duration.zero,
  );
  dio.httpClientAdapter = server;
  auth.api = AuthRepository(dio);
  await auth.restore();
  await t.pumpWidget(buildApp(dio, auth));
  await settle(t);
  return t.widget<LibraryApp>(find.byType(LibraryApp)).router;
}

Future<void> finish(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump();
}

void main() {
  testWidgets('показывается индикатор загрузки', (t) async {
    final server = FakeServer();
    final router = await start(t, server);
    server.gate = Completer();
    router.go('/books');
    await t.pump();
    await t.pump();
    await t.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    server.gate!.complete();
    server.gate = null;
    await settle(t);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await finish(t);
  });

  testWidgets('пустой результат показывает сообщение', (t) async {
    final router = await start(t, FakeServer());
    router.go('/books?search=zzz');
    await settle(t);
    expect(find.text('По заданным условиям ничего не найдено'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await finish(t);
  });

  testWidgets('ошибка показывается с кнопкой повтора', (t) async {
    final server = FakeServer()..failStatus = 500;
    final router = await start(t, server);
    router.go('/books');
    await settle(t);
    expect(find.text('Повторить'), findsOneWidget);
    server.failStatus = null;
    await t.tap(find.text('Повторить'));
    await settle(t);
    expect(find.textContaining('Очень длинное название'), findsWidgets);
    await finish(t);
  });

  testWidgets('форма с пустыми полями не отправляется', (t) async {
    final router = await start(t, FakeServer());
    router.go('/books/new');
    await settle(t);
    await t.tap(find.text('Создать'));
    await settle(t);
    expect(find.text('Поле обязательно'), findsWidgets);
    expect(find.text('Новая книга'), findsOneWidget);
    await finish(t);
  });

  testWidgets('читателю недоступна кнопка добавления', (t) async {
    final router = await start(t, FakeServer(), role: 'reader');
    router.go('/books');
    await settle(t);
    expect(find.text('Добавить'), findsNothing);
    await finish(t);
  });

  testWidgets('библиотекарю доступна кнопка добавления', (t) async {
    final router = await start(t, FakeServer());
    router.go('/books');
    await settle(t);
    expect(find.text('Добавить'), findsOneWidget);
    await finish(t);
  });

  testWidgets('чужой адрес открывает экран отказа', (t) async {
    final router = await start(t, FakeServer(), role: 'reader');
    router.go('/admin/stats');
    await settle(t);
    expect(find.text('Доступ запрещён'), findsOneWidget);
    await finish(t);
  });

  testWidgets('после восстановления связи список загружается сам', (t) async {
    final server = FakeServer()..down = true;
    final router = await start(t, server);
    router.go('/books');
    await settle(t);
    expect(find.text('Повторить'), findsOneWidget);
    server.down = false;
    await t.pump(const Duration(seconds: 6));
    await settle(t);
    expect(find.textContaining('Очень длинное название'), findsWidgets);
    await finish(t);
  });

  for (final (width, navigation) in [
    (360.0, NavigationBar),
    (768.0, NavigationRail),
    (1280.0, NavigationRail),
    (1920.0, NavigationRail),
  ]) {
    testWidgets('раскладка при ширине $width без переполнений', (t) async {
      final router = await start(
        t,
        FakeServer(),
        size: Size(width, 800),
        role: 'admin',
      );
      for (final path in [
        '/',
        '/books',
        '/books/new',
        '/readers',
        '/forbidden',
      ]) {
        router.go(path);
        await settle(t);
        expect(t.takeException(), isNull, reason: path);
      }
      router.go('/books');
      await settle(t);
      expect(find.byType(navigation), findsOneWidget);
      expect(
        find.byType(DataTable),
        width < 600 ? findsNothing : findsOneWidget,
      );
      await finish(t);
    });
  }
}
