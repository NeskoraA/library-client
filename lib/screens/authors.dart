import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';
import '../models/list_query.dart';
import '../state/entity_list_notifier.dart';
import '../validation/validators.dart';
import '../widgets/entity_detail_screen.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_list_screen.dart';
import '../widgets/entity_table.dart';

Widget authorList(ListQuery query) => EntityListScreen<Author>(
  title: 'Авторы',
  query: query,
  searchLabel: 'Поиск по имени или стране',
  itemTitle: (a) => a.fullName,
  columns:
      (context) => [
        TableColumnSpec(
          label: 'Автор',
          sortField: 'fullName',
          build: (a) => Text(a.fullName),
        ),
        TableColumnSpec(
          label: 'Страна',
          sortField: 'country',
          build: (a) => Text(a.country),
        ),
        TableColumnSpec(
          label: 'Год рождения',
          sortField: 'birthYear',
          numeric: true,
          build: (a) => Text('${a.birthYear}'),
        ),
      ],
);

Widget authorDetail(int? id) => EntityDetailScreen<Author>(
  basePath: '/authors',
  id: id,
  title: 'Карточка автора',
  heading: (a) => a.fullName,
  rows:
      (context, a) => [
        DetailRow('Страна', a.country),
        DetailRow('Год рождения', '${a.birthYear}'),
        DetailRow.links('Книги', [
          ('Открыть книги', '/books?authorId=${a.id}'),
        ]),
      ],
);

Widget authorForm(int? id) => EntityFormScreen(
  basePath: '/authors',
  id: id,
  title: id == null ? 'Новый автор' : 'Изменение автора',
  loadValues: (context) async {
    if (id == null) return {'fullName': '', 'country': '', 'birthYear': ''};
    final a = await context.read<EntityListNotifier<Author>>().findById(id);
    if (a == null) return null;
    return {
      'fullName': a.fullName,
      'country': a.country,
      'birthYear': '${a.birthYear}',
    };
  },
  buildFields:
      (context, values) => [
        TextFieldSpec(
          'fullName',
          'Автор (Фамилия И. О.)',
          validator: combine([requiredField, maxLength(100), personName]),
        ),
        TextFieldSpec(
          'country',
          'Страна',
          validator: combine([requiredField, maxLength(60)]),
        ),
        TextFieldSpec(
          'birthYear',
          'Год рождения',
          numeric: true,
          validator: combine([
            requiredField,
            integer,
            intRange(1000, currentYear),
          ]),
        ),
      ],
  onSave: (context, v) async {
    final saved = await context.read<EntityListNotifier<Author>>().save(
      Author(
        id: id ?? 0,
        fullName: (v['fullName'] as String).trim(),
        country: (v['country'] as String).trim(),
        birthYear: int.parse(v['birthYear'] as String),
      ),
      isNew: id == null,
    );
    return SaveResult.success(saved.id);
  },
);
