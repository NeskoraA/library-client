import 'package:flutter/material.dart';

import '../models/page_result.dart';

class PaginationBar extends StatelessWidget {
  final PageResult result;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onSize;

  const PaginationBar({
    super.key,
    required this.result,
    required this.onPage,
    required this.onSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Первая',
            icon: const Icon(Icons.first_page),
            onPressed: result.hasPrevious ? () => onPage(1) : null,
          ),
          IconButton(
            tooltip: 'Предыдущая',
            icon: const Icon(Icons.chevron_left),
            onPressed:
                result.hasPrevious ? () => onPage(result.page - 1) : null,
          ),
          Text('Страница ${result.page} из ${result.totalPages}'),
          IconButton(
            tooltip: 'Следующая',
            icon: const Icon(Icons.chevron_right),
            onPressed: result.hasNext ? () => onPage(result.page + 1) : null,
          ),
          IconButton(
            tooltip: 'Последняя',
            icon: const Icon(Icons.last_page),
            onPressed: result.hasNext ? () => onPage(result.totalPages) : null,
          ),
          const SizedBox(width: 12),
          Text('Всего: ${result.total}'),
          const SizedBox(width: 12),
          const Text('На странице:'),
          DropdownButton<int>(
            value: result.size,
            items: [
              for (final s in pageSizes)
                DropdownMenuItem(value: s, child: Text('$s')),
            ],
            onChanged: (v) => onSize(v ?? 10),
          ),
        ],
      ),
    );
  }
}
