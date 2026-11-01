import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../models/list_query.dart';
import '../state/catalog_lookups.dart';
import '../state/entity_list_notifier.dart';
import '../validation/validators.dart';
import '../widgets/entity_detail_screen.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_list_screen.dart';
import '../widgets/entity_table.dart';

Widget bookList(ListQuery query) => EntityListScreen<Book>(
  title: 'Книги',
  query: query,
  searchLabel: 'Поиск по названию или ISBN',
  itemTitle: (b) => b.title,
  filters: [
    FilterSpec.dropdown(
      'genreId',
      'Жанр',
      (c) => [
        for (final g in c.watch<CatalogLookups>().activeGenres)
          ('${g.id}', g.name),
      ],
    ),
    FilterSpec.dropdown(
      'publisherId',
      'Издательство',
      (c) => [
        for (final p in c.watch<CatalogLookups>().activePublishers)
          ('${p.id}', p.name),
      ],
    ),
    const FilterSpec.number('yearFrom', 'Год от'),
    const FilterSpec.number('yearTo', 'Год до'),
  ],
  columns:
      (context) => [
        TableColumnSpec(
          label: 'Название',
          sortField: 'title',
          build: (b) => Text(b.title),
        ),
        TableColumnSpec(
          label: 'Год',
          sortField: 'year',
          numeric: true,
          build: (b) => Text('${b.year}'),
        ),
        TableColumnSpec(
          label: 'Страниц',
          sortField: 'pages',
          numeric: true,
          build: (b) => Text('${b.pages}'),
        ),
        TableColumnSpec(
          label: 'Издательство',
          build: (b) => Text(b.publisherName),
        ),
        TableColumnSpec(
          label: 'Жанры',
          build: (b) => Text(b.genreNames.join(', ')),
        ),
        TableColumnSpec(
          label: 'В наличии',
          sortField: 'copiesAvailable',
          numeric: true,
          build: (b) => Text('${b.copiesAvailable} из ${b.copiesTotal}'),
        ),
      ],
);

Widget bookDetail(int? id) => EntityDetailScreen<Book>(
  basePath: '/books',
  id: id,
  title: 'Карточка книги',
  heading: (b) => b.title,
  rows:
      (context, b) => [
        DetailRow('ISBN', b.isbn),
        DetailRow('Год издания', '${b.year}'),
        DetailRow('Страниц', '${b.pages}'),
        DetailRow.links('Издательство', [
          (b.publisherName, '/publishers/${b.publisherId}'),
        ]),
        DetailRow.links('Авторы', [
          for (var i = 0; i < b.authorIds.length; i++)
            (
              i < b.authorNames.length ? b.authorNames[i] : '?',
              '/authors/${b.authorIds[i]}',
            ),
        ]),
        DetailRow.links('Жанры', [
          for (var i = 0; i < b.genreIds.length; i++)
            (
              i < b.genreNames.length ? b.genreNames[i] : '?',
              '/genres/${b.genreIds[i]}',
            ),
        ]),
        DetailRow(
          'Экземпляров',
          '${b.copiesAvailable} из ${b.copiesTotal} в наличии',
        ),
      ],
);

Widget bookForm(int? id) => EntityFormScreen(
  basePath: '/books',
  id: id,
  title: id == null ? 'Новая книга' : 'Изменение книги',
  loadValues: (context) async {
    final lookups = context.read<CatalogLookups>();
    final notifier = context.read<EntityListNotifier<Book>>();
    await lookups.ensureLoaded();
    if (id == null) {
      return {
        'title': '',
        'isbn': '',
        'year': '',
        'pages': '',
        'publisherId': null,
        'authorIds': <int>[],
        'genreIds': <int>[],
        'copiesTotal': '1',
      };
    }
    final b = await notifier.findById(id);
    if (b == null) return null;
    return {
      'title': b.title,
      'isbn': b.isbn,
      'year': '${b.year}',
      'pages': '${b.pages}',
      'publisherId': b.publisherId,
      'authorIds': [...b.authorIds],
      'genreIds': [...b.genreIds],
      'copiesTotal': '${b.copiesTotal}',
    };
  },
  buildFields: (context, values) {
    final lookups = context.watch<CatalogLookups>();
    return [
      TextFieldSpec(
        'title',
        'Название',
        validator: combine([requiredField, maxLength(200)]),
      ),
      TextFieldSpec(
        'isbn',
        'ISBN',
        hint: '978-5-17-118366-4',
        validator: combine([requiredField, isbn]),
      ),
      TextFieldSpec(
        'year',
        'Год издания',
        numeric: true,
        validator: combine([
          requiredField,
          integer,
          intRange(1450, currentYear),
        ]),
      ),
      TextFieldSpec(
        'pages',
        'Число страниц',
        numeric: true,
        validator: combine([
          requiredField,
          integer,
          positive,
          intRange(1, 10000),
        ]),
      ),
      DropdownFieldSpec(
        'publisherId',
        'Издательство',
        options: [for (final p in lookups.activePublishers) (p.id, p.name)],
        validator: requiredChoice,
      ),
      MultiSelectFieldSpec(
        'authorIds',
        'Авторы',
        options: [for (final a in lookups.activeAuthors) (a.id, a.fullName)],
        validator: minSelected(1, 'Выберите хотя бы одного автора'),
      ),
      MultiSelectFieldSpec(
        'genreIds',
        'Жанры',
        options: [for (final g in lookups.activeGenres) (g.id, g.name)],
        validator: minSelected(1, 'Выберите хотя бы один жанр'),
      ),
      TextFieldSpec(
        'copiesTotal',
        'Всего экземпляров',
        numeric: true,
        validator: combine([requiredField, integer, intRange(0, 1000)]),
      ),
    ];
  },
  onSave: (context, v) async {
    final saved = await context.read<EntityListNotifier<Book>>().save(
      Book(
        id: id ?? 0,
        title: (v['title'] as String).trim(),
        isbn: (v['isbn'] as String).trim(),
        year: int.parse(v['year'] as String),
        pages: int.parse(v['pages'] as String),
        publisherId: v['publisherId'] as int,
        authorIds: v['authorIds'] as List<int>,
        genreIds: v['genreIds'] as List<int>,
        copiesTotal: int.parse(v['copiesTotal'] as String),
      ),
      isNew: id == null,
    );
    return SaveResult.success(saved.id);
  },
);
