import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'models/author.dart';
import 'models/book.dart';
import 'models/genre.dart';
import 'models/loan.dart';
import 'models/publisher.dart';
import 'models/reader.dart';
import 'repositories/auth_repository.dart';
import 'repositories/entity_repositories.dart';
import 'router.dart';
import 'state/admin_notifier.dart';
import 'state/auth_notifier.dart';
import 'state/catalog_lookups.dart';
import 'state/entity_list_notifier.dart';
import 'state/loan_list_notifier.dart';
import 'widgets/inactivity_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();
  final auth = AuthNotifier(prefs);
  final dio = buildDio(
    tokenProvider: () => auth.accessToken,
    onUnauthorized: auth.refreshTokens,
  );
  auth.api = AuthRepository(dio);
  await auth.restore();
  runApp(buildApp(dio, auth));
}

Widget buildApp(Dio dio, AuthNotifier auth) {
  final books = BookRepository(dio);
  final authors = AuthorRepository(dio);
  final genres = GenreRepository(dio);
  final publishers = PublisherRepository(dio);
  final readers = ReaderRepository(dio);
  final loans = LoanRepository(dio);
  final lookups = CatalogLookups(authors, genres, publishers, books, readers);
  lookups.ensureLoaded();
  final router = buildRouter(auth);

  return MultiProvider(
    providers: [
      Provider<Dio>.value(value: dio),
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider.value(value: lookups),
      Provider(create: (_) => AdminNotifier(auth.api, books, readers, loans)),
      ChangeNotifierProvider(
        create:
            (_) => EntityListNotifier<Book>(
              books,
              onRecovered: lookups.ensureLoaded,
            ),
      ),
      ChangeNotifierProvider(
        create:
            (_) => EntityListNotifier<Author>(
              authors,
              onDataChanged: lookups.reload,
              onRecovered: lookups.ensureLoaded,
            ),
      ),
      ChangeNotifierProvider(
        create:
            (_) => EntityListNotifier<Genre>(
              genres,
              onDataChanged: lookups.reload,
              onRecovered: lookups.ensureLoaded,
            ),
      ),
      ChangeNotifierProvider(
        create:
            (_) => EntityListNotifier<Publisher>(
              publishers,
              onDataChanged: lookups.reload,
              onRecovered: lookups.ensureLoaded,
            ),
      ),
      ChangeNotifierProvider(
        create:
            (_) => EntityListNotifier<Reader>(
              readers,
              onRecovered: lookups.ensureLoaded,
            ),
      ),
      ChangeNotifierProvider<EntityListNotifier<Loan>>(
        create:
            (_) => LoanListNotifier(loans, onRecovered: lookups.ensureLoaded),
      ),
    ],
    child: LibraryApp(router: router, auth: auth),
  );
}

class LibraryApp extends StatelessWidget {
  final GoRouter router;
  final AuthNotifier auth;

  const LibraryApp({super.key, required this.router, required this.auth});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Библиотека',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        fontFamily: 'AppRoboto',
      ),
      routerConfig: router,
      builder: (context, child) => InactivityWatcher(auth: auth, child: child!),
    );
  }
}
