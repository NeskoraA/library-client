import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/genre.dart';
import '../models/list_query.dart';
import '../state/entity_list_notifier.dart';
import '../validation/validators.dart';
import '../widgets/entity_detail_screen.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_list_screen.dart';
import '../widgets/entity_table.dart';

Widget genreList(ListQuery query) => EntityListScreen<Genre>(
  title: 'Жанры',
  query: query,
  searchLabel: 'Поиск по названию или описанию',
  itemTitle: (g) => g.name,
  columns:
      (context) => [
        TableColumnSpec(
          label: 'Код',
          sortField: 'id',
          numeric: true,
          build: (g) => Text('${g.id}'),
        ),
        TableColumnSpec(
          label: 'Название',
          sortField: 'name',
          build: (g) => Text(g.name),
        ),
        TableColumnSpec(
          label: 'Описание',
          sortField: 'description',
          build: (g) => Text(g.description),
        ),
      ],
);

Widget genreDetail(int? id) => EntityDetailScreen<Genre>(
  basePath: '/genres',
  id: id,
  title: 'Карточка жанра',
  heading: (g) => g.name,
  rows:
      (context, g) => [
        DetailRow('Описание', g.description.isEmpty ? 'нет' : g.description),
        DetailRow.links('Книги', [('Открыть книги', '/books?genreId=${g.id}')]),
      ],
);

Widget genreForm(int? id) => EntityFormScreen(
  basePath: '/genres',
  id: id,
  title: id == null ? 'Новый жанр' : 'Изменение жанра',
  loadValues: (context) async {
    if (id == null) return {'name': '', 'description': ''};
    final g = await context.read<EntityListNotifier<Genre>>().findById(id);
    if (g == null) return null;
    return {'name': g.name, 'description': g.description};
  },
  buildFields:
      (context, values) => [
        TextFieldSpec(
          'name',
          'Название',
          validator: combine([requiredField, minLength(2), maxLength(40)]),
        ),
        TextFieldSpec(
          'description',
          'Описание',
          maxLines: 3,
          validator: maxLength(300),
        ),
      ],
  onSave: (context, v) async {
    final saved = await context.read<EntityListNotifier<Genre>>().save(
      Genre(
        id: id ?? 0,
        name: (v['name'] as String).trim(),
        description: (v['description'] as String).trim(),
      ),
      isNew: id == null,
    );
    return SaveResult.success(saved.id);
  },
);
