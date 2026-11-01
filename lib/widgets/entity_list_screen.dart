import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/entity.dart';
import '../models/list_query.dart';
import '../state/auth_notifier.dart';
import '../state/entity_list_notifier.dart';
import '../state/load_status.dart';
import '../state/permissions.dart';
import 'app_scaffold.dart';
import 'entity_table.dart';
import 'pagination_bar.dart';
import 'status_views.dart';

class FilterSpec {
  final String key;
  final String label;
  final List<(String, String)> Function(BuildContext context)? options;
  final double width;

  const FilterSpec.dropdown(this.key, this.label, this.options) : width = 180;

  const FilterSpec.number(this.key, this.label) : options = null, width = 110;

  bool get isNumber => options == null;
}

class EntityListScreen<T extends Entity<T>> extends StatefulWidget {
  final String title;
  final ListQuery query;
  final String searchLabel;
  final List<FilterSpec> filters;
  final List<TableColumnSpec<T>> Function(BuildContext context) columns;
  final String Function(T item) itemTitle;
  final Future<String?> Function(BuildContext context, T item)?
  deleteBlockedReason;
  final bool canEdit;
  final Permission editPermission;
  final List<Widget> Function(BuildContext context, T item)? extraActions;

  const EntityListScreen({
    super.key,
    required this.title,
    required this.query,
    required this.searchLabel,
    required this.columns,
    required this.itemTitle,
    this.filters = const [],
    this.deleteBlockedReason,
    this.canEdit = true,
    this.editPermission = Permission.editCatalog,
    this.extraActions,
  });

  @override
  State<EntityListScreen<T>> createState() => _EntityListScreenState<T>();
}

class _EntityListScreenState<T extends Entity<T>>
    extends State<EntityListScreen<T>> {
  final _searchController = TextEditingController();
  final Map<String, TextEditingController> _numberControllers = {};
  Timer? _debounce;
  bool _canWrite = false;
  bool _canRestore = false;
  bool _canHardDelete = false;

  ListQuery get q => widget.query;
  String get _path => q.path;

  @override
  void initState() {
    super.initState();
    for (final f in widget.filters.where((f) => f.isNumber)) {
      _numberControllers[f.key] = TextEditingController();
    }
    _fillControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(EntityListScreen<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _fillControllers();
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    for (final c in _numberControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _fillControllers() {
    _setText(_searchController, q.search);
    _numberControllers.forEach((key, c) => _setText(c, q.filters[key] ?? ''));
  }

  void _setText(TextEditingController controller, String text) {
    if (controller.text != text) controller.text = text;
  }

  void _sync() {
    if (!mounted) return;
    context.read<EntityListNotifier<T>>().applyQuery(widget.query);
  }

  void _go(ListQuery query) => context.go(query.toLocation());

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      var next = q.copyWith(search: _searchController.text);
      _numberControllers.forEach((key, c) {
        next = next.withFilter(key, int.tryParse(c.text)?.toString());
      });
      _go(next);
    });
  }

  Future<bool> _checkCanDelete(List<T> items) async {
    for (final item in items) {
      final reason = await widget.deleteBlockedReason?.call(context, item);
      if (reason != null) {
        if (mounted) await showMessage(context, 'Удаление невозможно', reason);
        return false;
      }
    }
    return true;
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deleteSelected(EntityListNotifier<T> notifier) async {
    final items =
        notifier.result.items
            .where((e) => notifier.selected.contains(e.id))
            .toList();
    final allowed = await _checkCanDelete(items).catchError((_) => false);
    if (!allowed || !mounted) return;
    final ok = await confirmAction(
      context,
      'Удаление',
      'Удалить выбранные записи (${notifier.selected.length})?',
    );
    if (ok) await _run(notifier.deleteSelected);
  }

  Future<void> _softDelete(EntityListNotifier<T> notifier, T item) async {
    await _run(() async {
      if (await _checkCanDelete([item])) await notifier.softDelete(item.id);
    });
  }

  Future<void> _hardDelete(EntityListNotifier<T> notifier, T item) async {
    final allowed = await _checkCanDelete([item]).catchError((_) => false);
    if (!allowed || !mounted) return;
    final ok = await confirmAction(
      context,
      'Удаление навсегда',
      'Запись «${widget.itemTitle(item)}» будет удалена без возможности восстановления.',
    );
    if (ok) await _run(() => notifier.hardDelete(item.id));
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<EntityListNotifier<T>>();
    final auth = context.watch<AuthNotifier>();
    _canWrite = auth.can(widget.editPermission);
    _canRestore = auth.can(Permission.restore);
    _canHardDelete = auth.can(Permission.hardDelete);

    return AppScaffold(
      title: widget.title,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (_canWrite)
                  FilledButton.icon(
                    onPressed: () => context.go('$_path/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить'),
                  ),
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: widget.searchLabel,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _onTextChanged(),
                  ),
                ),
                for (final f in widget.filters) _buildFilter(f),
                if (_canRestore)
                  FilterChip(
                    label: const Text('Показывать удалённые'),
                    selected: q.includeDeleted,
                    onSelected: (v) => _go(q.copyWith(includeDeleted: v)),
                  ),
              ],
            ),
          ),
          if (notifier.hasSelection)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Выбрано: ${notifier.selected.length}'),
                  FilledButton.icon(
                    onPressed: () => _deleteSelected(notifier),
                    icon: const Icon(Icons.delete),
                    label: const Text('Удалить выбранные'),
                  ),
                  TextButton(
                    onPressed: notifier.clearSelection,
                    child: const Text('Снять выделение'),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildContent(notifier)),
          if (notifier.status == LoadStatus.success &&
              notifier.result.total > 0)
            PaginationBar(
              result: notifier.result,
              onPage: (p) => _go(q.copyWith(page: p)),
              onSize: (s) => _go(q.copyWith(size: s)),
            ),
        ],
      ),
    );
  }

  Widget _buildFilter(FilterSpec f) {
    if (f.isNumber) {
      return SizedBox(
        width: f.width,
        child: TextField(
          controller: _numberControllers[f.key],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: f.label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (_) => _onTextChanged(),
        ),
      );
    }
    final options = f.options!(context);
    final current = q.filters[f.key];
    return SizedBox(
      width: f.width,
      child: DropdownButtonFormField<String?>(
        key: ValueKey('${f.key}:$current:${options.length}'),
        value: options.any((o) => o.$1 == current) ? current : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: f.label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Все')),
          for (final (value, label) in options)
            DropdownMenuItem(value: value, child: Text(label)),
        ],
        onChanged: (v) => _go(q.withFilter(f.key, v)),
      ),
    );
  }

  Widget _buildContent(EntityListNotifier<T> notifier) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(message: notifier.error ?? '', onRetry: notifier.load);
      case LoadStatus.success:
        if (notifier.result.items.isEmpty) {
          return EmptyView(
            onReset:
                () => _go(ListQuery(path: _path, defaultSort: q.defaultSort)),
          );
        }
    }
    return EntityTable<T>(
      items: notifier.result.items,
      idOf: (e) => e.id,
      selected: notifier.selected,
      onToggleSelect: _canWrite ? notifier.toggleSelection : null,
      isInactive: (e) => e.isDeleted,
      onOpen: (e) => context.go('$_path/${e.id}'),
      sortField: q.sortField,
      sortAscending: q.sortAscending,
      onSort:
          (field) => _go(
            q.copyWith(
              sortField: field,
              sortAscending: field == q.sortField ? !q.sortAscending : true,
            ),
          ),
      columns: widget.columns(context),
      actions:
          !_canWrite && !_canRestore && widget.extraActions == null
              ? null
              : (e) => [
                ...?widget.extraActions?.call(context, e),
                if (widget.canEdit && _canWrite)
                  IconButton(
                    tooltip: 'Изменить',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => context.go('$_path/${e.id}/edit'),
                  ),
                if (e.isDeleted) ...[
                  if (_canRestore)
                    IconButton(
                      tooltip: 'Восстановить',
                      icon: const Icon(Icons.restore),
                      onPressed: () => _run(() => notifier.restore(e.id)),
                    ),
                  if (_canHardDelete)
                    IconButton(
                      tooltip: 'Удалить навсегда',
                      icon: const Icon(Icons.delete_forever),
                      onPressed: () => _hardDelete(notifier, e),
                    ),
                ] else if (_canWrite)
                  IconButton(
                    tooltip: 'Удалить',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _softDelete(notifier, e),
                  ),
              ],
    );
  }
}
