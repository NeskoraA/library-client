import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;
  final void Function(T item)? onOpen;
  final bool Function(T item)? isInactive;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
    this.onOpen,
    this.isInactive,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder:
          (context, constraints) =>
              constraints.maxWidth < 600
                  ? _buildCards(context)
                  : _buildTable(context, constraints),
    );
  }

  Widget _buildTable(BuildContext context, BoxConstraints constraints) {
    final sortIndex = columns.indexWhere(
      (c) => c.sortField != null && c.sortField == sortField,
    );
    final inactiveColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final table = DataTable(
      sortColumnIndex: sortIndex >= 0 ? sortIndex : null,
      sortAscending: sortAscending,
      showCheckboxColumn: onToggleSelect != null,
      columns: [
        for (final col in columns)
          DataColumn(
            label: Text(col.label),
            numeric: col.numeric,
            onSort:
                col.sortField == null || onSort == null
                    ? null
                    : (_, _) => onSort!(col.sortField!),
          ),
        if (actions != null) const DataColumn(label: Text('Действия')),
      ],
      rows: [
        for (final item in items)
          DataRow(
            selected: selected.contains(idOf(item)),
            onSelectChanged:
                onToggleSelect == null
                    ? null
                    : (_) => onToggleSelect!(idOf(item)),
            color:
                (isInactive?.call(item) ?? false)
                    ? WidgetStatePropertyAll(inactiveColor)
                    : null,
            cells: [
              for (final col in columns)
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: DefaultTextStyle.merge(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: col.build(item),
                    ),
                  ),
                  onTap: onOpen == null ? null : () => onOpen!(item),
                ),
              if (actions != null)
                DataCell(
                  Row(mainAxisSize: MainAxisSize.min, children: actions!(item)),
                ),
            ],
          ),
      ],
    );

    return Scrollbar(
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: table,
          ),
        ),
      ),
    );
  }

  Widget _buildCards(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final id = idOf(item);
        final inactive = isInactive?.call(item) ?? false;
        return Card(
          color: inactive ? theme.colorScheme.surfaceContainerHighest : null,
          child: InkWell(
            onTap: onOpen == null ? null : () => onOpen!(item),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (onToggleSelect != null)
                        Checkbox(
                          value: selected.contains(id),
                          onChanged: (_) => onToggleSelect!(id),
                        ),
                      Expanded(
                        child: DefaultTextStyle.merge(
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          child: columns.first.build(item),
                        ),
                      ),
                      if (actions != null) ...actions!(item),
                    ],
                  ),
                  for (final col in columns.skip(1))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text(
                            '${col.label}: ',
                            style: theme.textTheme.bodySmall,
                          ),
                          Flexible(
                            child: DefaultTextStyle.merge(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              child: col.build(item),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
