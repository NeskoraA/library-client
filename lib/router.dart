import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'models/list_query.dart';
import 'screens/admin_screens.dart' deferred as admin;
import 'screens/auth_screens.dart';
import 'screens/authors.dart';
import 'screens/books.dart';
import 'screens/genres.dart';
import 'screens/home_screens.dart';
import 'screens/loans.dart';
import 'screens/not_found_screen.dart';
import 'screens/publishers.dart';
import 'screens/readers.dart';
import 'state/auth_notifier.dart';
import 'state/permissions.dart';
import 'widgets/entity_form.dart';
import 'widgets/status_views.dart';

Future<bool> _guardForm(BuildContext context, GoRouterState state) async =>
    !unsavedChanges.value || await confirmLeave(context);

Widget _deferred(Widget Function() build) => FutureBuilder(
  future: admin.loadLibrary(),
  builder:
      (context, snapshot) =>
          snapshot.connectionState == ConnectionState.done
              ? build()
              : const LoadingView(),
);

GoRouter buildRouter(AuthNotifier auth) {
  GoRouterRedirect require(Permission permission) =>
      (context, state) => auth.can(permission) ? null : '/forbidden';

  GoRoute entityRoutes({
    required String path,
    required String defaultSort,
    required Permission view,
    required Permission edit,
    required Widget Function(ListQuery query) list,
    required Widget Function(int? id) detail,
    Widget Function(int? id)? form,
  }) {
    return GoRoute(
      path: path,
      redirect: require(view),
      builder:
          (context, state) => list(
            ListQuery.fromParams(path, defaultSort, state.uri.queryParameters),
          ),
      routes: [
        if (form != null)
          GoRoute(
            path: 'new',
            redirect: require(edit),
            onExit: _guardForm,
            builder: (context, state) => form(null),
          ),
        GoRoute(
          path: ':id',
          builder:
              (context, state) =>
                  detail(int.tryParse(state.pathParameters['id']!)),
          routes: [
            if (form != null)
              GoRoute(
                path: 'edit',
                redirect: require(edit),
                onExit: _guardForm,
                builder:
                    (context, state) =>
                        form(int.tryParse(state.pathParameters['id']!)),
              ),
          ],
        ),
      ],
    );
  }

  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';
      if (!loggedIn && !isPublic) {
        final from = state.uri.toString();
        return from == '/' || target == '/forbidden'
            ? '/login'
            : '/login?from=${Uri.encodeComponent(from)}';
      }
      if (loggedIn && isPublic) {
        return state.uri.queryParameters['from'] ?? '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/', builder: (c, s) => const DashboardScreen()),
      GoRoute(path: '/forbidden', builder: (c, s) => const ForbiddenScreen()),
      entityRoutes(
        path: '/books',
        defaultSort: 'title',
        view: Permission.viewCatalog,
        edit: Permission.editCatalog,
        list: bookList,
        detail: bookDetail,
        form: bookForm,
      ),
      entityRoutes(
        path: '/authors',
        defaultSort: 'fullName',
        view: Permission.viewCatalog,
        edit: Permission.editCatalog,
        list: authorList,
        detail: authorDetail,
        form: authorForm,
      ),
      entityRoutes(
        path: '/genres',
        defaultSort: 'name',
        view: Permission.viewCatalog,
        edit: Permission.editCatalog,
        list: genreList,
        detail: genreDetail,
        form: genreForm,
      ),
      entityRoutes(
        path: '/publishers',
        defaultSort: 'name',
        view: Permission.viewCatalog,
        edit: Permission.editCatalog,
        list: publisherList,
        detail: publisherDetail,
        form: publisherForm,
      ),
      entityRoutes(
        path: '/readers',
        defaultSort: 'fullName',
        view: Permission.manageReaders,
        edit: Permission.manageReaders,
        list: readerList,
        detail: readerDetail,
        form: readerForm,
      ),
      entityRoutes(
        path: '/loans',
        defaultSort: 'issuedAt',
        view: Permission.manageLoans,
        edit: Permission.manageLoans,
        list: loanList,
        detail: loanDetail,
        form: loanForm,
      ),
      entityRoutes(
        path: '/my-loans',
        defaultSort: 'issuedAt',
        view: Permission.viewOwnLoans,
        edit: Permission.viewOwnLoans,
        list: myLoanList,
        detail: myLoanDetail,
      ),
      GoRoute(
        path: '/admin/users',
        redirect: require(Permission.manageUsers),
        builder: (c, s) => _deferred(() => admin.UsersScreen()),
      ),
      GoRoute(
        path: '/admin/stats',
        redirect: require(Permission.viewStats),
        builder: (c, s) => _deferred(() => admin.StatsScreen()),
      ),
    ],
    errorBuilder:
        (context, state) => NotFoundScreen(location: state.uri.toString()),
  );
}
