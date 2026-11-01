import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../models/list_query.dart';
import '../models/publisher.dart';
import '../state/entity_list_notifier.dart';
import '../validation/validators.dart';
import '../widgets/entity_detail_screen.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_list_screen.dart';
import '../widgets/entity_table.dart';

Widget publisherList(ListQuery query) => EntityListScreen<Publisher>(
  title: 'Издательства',
  query: query,
  searchLabel: 'Поиск по названию или городу',
  itemTitle: (p) => p.name,
  deleteBlockedReason: (context, p) async {
    final count = await context.read<EntityListNotifier<Book>>().count({
      'publisherId': '${p.id}',
    });
    return count == 0
        ? null
        : 'Издательство «${p.name}» нельзя удалить: на него ссылаются книги ($count шт.). Сначала измените издательство у этих книг.';
  },
  columns:
      (context) => [
        TableColumnSpec(
          label: 'Название',
          sortField: 'name',
          build: (p) => Text(p.name),
        ),
        TableColumnSpec(
          label: 'Город',
          sortField: 'city',
          build: (p) => Text(p.city),
        ),
        TableColumnSpec(
          label: 'Основано',
          sortField: 'foundedYear',
          numeric: true,
          build: (p) => Text('${p.foundedYear}'),
        ),
      ],
);

Widget publisherDetail(int? id) => EntityDetailScreen<Publisher>(
  basePath: '/publishers',
  id: id,
  title: 'Карточка издательства',
  heading: (p) => p.name,
  rows:
      (context, p) => [
        DetailRow('Город', p.city),
        DetailRow('Год основания', '${p.foundedYear}'),
        DetailRow.links('Книги', [
          ('Открыть книги', '/books?publisherId=${p.id}'),
        ]),
      ],
);

Widget publisherForm(int? id) => EntityFormScreen(
  basePath: '/publishers',
  id: id,
  title: id == null ? 'Новое издательство' : 'Изменение издательства',
  loadValues: (context) async {
    if (id == null) return {'name': '', 'city': '', 'foundedYear': ''};
    final p = await context.read<EntityListNotifier<Publisher>>().findById(id);
    if (p == null) return null;
    return {'name': p.name, 'city': p.city, 'foundedYear': '${p.foundedYear}'};
  },
  buildFields:
      (context, values) => [
        TextFieldSpec(
          'name',
          'Название',
          validator: combine([requiredField, maxLength(100)]),
        ),
        TextFieldSpec(
          'city',
          'Город',
          validator: combine([requiredField, maxLength(60), letters]),
        ),
        TextFieldSpec(
          'foundedYear',
          'Год основания',
          numeric: true,
          validator: combine([
            requiredField,
            integer,
            intRange(1400, currentYear),
          ]),
        ),
      ],
  onSave: (context, v) async {
    final saved = await context.read<EntityListNotifier<Publisher>>().save(
      Publisher(
        id: id ?? 0,
        name: (v['name'] as String).trim(),
        city: (v['city'] as String).trim(),
        foundedYear: int.parse(v['foundedYear'] as String),
      ),
      isNew: id == null,
    );
    return SaveResult.success(saved.id);
  },
);
