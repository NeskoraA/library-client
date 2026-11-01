import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/entity.dart';
import '../state/auth_notifier.dart';
import '../state/entity_list_notifier.dart';
import '../state/permissions.dart';
import 'app_scaffold.dart';
import 'status_views.dart';

class DetailRow {
  final String label;
  final String value;
  final List<(String, String)> links;

  const DetailRow(this.label, this.value) : links = const [];

  const DetailRow.links(this.label, this.links) : value = '';
}

class EntityDetailScreen<T extends Entity<T>> extends StatefulWidget {
  final String basePath;
  final int? id;
  final String title;
  final String Function(T item) heading;
  final List<DetailRow> Function(BuildContext context, T item) rows;
  final bool canEdit;
  final Permission editPermission;

  const EntityDetailScreen({
    super.key,
    required this.basePath,
    required this.id,
    required this.title,
    required this.heading,
    required this.rows,
    this.canEdit = true,
    this.editPermission = Permission.editCatalog,
  });

  @override
  State<EntityDetailScreen<T>> createState() => _EntityDetailScreenState<T>();
}

class _EntityDetailScreenState<T extends Entity<T>>
    extends State<EntityDetailScreen<T>> {
  late Future<T?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<T?> _load() async {
    final id = widget.id;
    if (id == null) return null;
    return context.read<EntityListNotifier<T>>().findById(id);
  }

  @override
  Widget build(BuildContext context) {
    final backLocation =
        context.read<EntityListNotifier<T>>().query?.toLocation() ??
        widget.basePath;
    return AppScaffold(
      title: widget.title,
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: 'Не удалось загрузить запись: ${snapshot.error}',
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final item = snapshot.data;
          if (item == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Запись не найдена'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go(backLocation),
                    child: const Text('К списку'),
                  ),
                ],
              ),
            );
          }
          final theme = Theme.of(context);
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.heading(item),
                          style: theme.textTheme.headlineSmall,
                        ),
                        if (item.isDeleted)
                          Text(
                            'Запись удалена',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        const SizedBox(height: 12),
                        for (final row in widget.rows(context, item))
                          _buildRow(row),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => context.go(backLocation),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('К списку'),
                            ),
                            if (widget.canEdit &&
                                context.watch<AuthNotifier>().can(
                                  widget.editPermission,
                                ))
                              FilledButton.icon(
                                onPressed:
                                    () => context.go(
                                      '${widget.basePath}/${item.id}/edit',
                                    ),
                                icon: const Icon(Icons.edit),
                                label: const Text('Изменить'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(DetailRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              row.label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child:
                row.links.isEmpty
                    ? Text(row.value)
                    : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final (text, link) in row.links)
                          ActionChip(
                            label: Text(text),
                            onPressed: () => context.go(link),
                          ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}
