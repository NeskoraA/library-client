import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../state/admin_notifier.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/entity_table.dart';
import '../widgets/status_views.dart';
import 'home_screens.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late Future<List<AppUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AdminNotifier>().users();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Пользователи',
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: 'Не удалось загрузить пользователей: ${snapshot.error}',
              onRetry:
                  () => setState(
                    () => _future = context.read<AdminNotifier>().users(),
                  ),
            );
          }
          return EntityTable<AppUser>(
            items: snapshot.data!,
            idOf: (u) => u.id,
            columns: [
              TableColumnSpec(label: 'Логин', build: (u) => Text(u.username)),
              TableColumnSpec(label: 'ФИО', build: (u) => Text(u.fullName)),
              TableColumnSpec(label: 'Почта', build: (u) => Text(u.email)),
              TableColumnSpec(label: 'Роль', build: (u) => Text(u.role.label)),
            ],
          );
        },
      ),
    );
  }
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<LibraryStats> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AdminNotifier>().stats();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Статистика',
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: 'Не удалось загрузить статистику: ${snapshot.error}',
              onRetry:
                  () => setState(
                    () => _future = context.read<AdminNotifier>().stats(),
                  ),
            );
          }
          final s = snapshot.data!;
          final items = [
            ('Книг в каталоге', s.books),
            ('Читателей', s.readers),
            ('Активных выдач', s.activeLoans),
            ('Просроченных выдач', s.overdueLoans),
            ('Возвращённых выдач', s.returnedLoans),
          ];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ResponsiveGrid(
              children: [
                for (final (label, value) in items)
                  SizedBox(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              '$value',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text(label),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
