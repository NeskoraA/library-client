import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/list_query.dart';
import '../models/loan.dart';
import '../state/catalog_lookups.dart';
import '../state/auth_notifier.dart';
import '../state/entity_list_notifier.dart';
import '../state/permissions.dart';
import '../state/loan_list_notifier.dart';
import '../validation/validators.dart';
import '../widgets/entity_detail_screen.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_list_screen.dart';
import '../widgets/entity_table.dart';

String _date(DateTime? d) => d == null ? 'нет' : formatDate(d.toLocal());

Widget loanList(ListQuery query) => EntityListScreen<Loan>(
  title: 'Выдачи',
  query: query,
  searchLabel: 'Поиск',
  itemTitle: (l) => '${l.bookTitle}, ${l.readerName}',
  canEdit: false,
  editPermission: Permission.manageLoans,
  filters: [
    FilterSpec.dropdown(
      'status',
      'Состояние',
      (c) => const [
        ('active', 'Активна'),
        ('overdue', 'Просрочена'),
        ('returned', 'Возвращена'),
      ],
    ),
  ],
  extraActions:
      (context, l) => [
        if (!l.isReturned &&
            context.watch<AuthNotifier>().can(Permission.manageLoans))
          IconButton(
            tooltip: 'Вернуть книгу',
            icon: const Icon(Icons.assignment_return_outlined),
            onPressed:
                () => (context.read<EntityListNotifier<Loan>>()
                        as LoanListNotifier)
                    .returnLoan(l.id),
          ),
      ],
  columns:
      (context) => [
        TableColumnSpec(label: 'Книга', build: (l) => Text(l.bookTitle)),
        TableColumnSpec(label: 'Читатель', build: (l) => Text(l.readerName)),
        TableColumnSpec(
          label: 'Выдана',
          sortField: 'issuedAt',
          build: (l) => Text(_date(l.issuedAt)),
        ),
        TableColumnSpec(
          label: 'Вернуть до',
          sortField: 'dueAt',
          build: (l) => Text(_date(l.dueAt)),
        ),
        TableColumnSpec(label: 'Состояние', build: (l) => Text(l.statusLabel)),
      ],
);

Widget loanDetail(int? id) => EntityDetailScreen<Loan>(
  basePath: '/loans',
  id: id,
  title: 'Выдача',
  heading: (l) => l.bookTitle,
  canEdit: false,
  rows:
      (context, l) => [
        DetailRow.links('Книга', [(l.bookTitle, '/books/${l.bookId}')]),
        DetailRow.links('Читатель', [(l.readerName, '/readers/${l.readerId}')]),
        DetailRow('Выдана', _date(l.issuedAt)),
        DetailRow('Вернуть до', _date(l.dueAt)),
        DetailRow('Возвращена', _date(l.returnedAt)),
        DetailRow('Состояние', l.statusLabel),
      ],
);

Widget loanForm(int? id) => EntityFormScreen(
  basePath: '/loans',
  id: id,
  title: 'Оформление выдачи',
  loadValues: (context) async {
    await context.read<CatalogLookups>().loadLoanOptions();
    return {'readerId': null, 'bookId': null, 'days': '14'};
  },
  buildFields: (context, values) {
    final lookups = context.watch<CatalogLookups>();
    return [
      DropdownFieldSpec(
        'readerId',
        'Читатель',
        options: [for (final r in lookups.readers) (r.id, r.fullName)],
        validator: requiredChoice,
      ),
      DropdownFieldSpec(
        'bookId',
        'Книга',
        options: [
          for (final b in lookups.books)
            (b.id, '${b.title} (свободно ${b.copiesAvailable})'),
        ],
        validator: requiredChoice,
      ),
      TextFieldSpec(
        'days',
        'Срок, дней',
        numeric: true,
        validator: combine([requiredField, integer, intRange(1, 90)]),
      ),
    ];
  },
  onSave: (context, v) async {
    final saved = await context.read<EntityListNotifier<Loan>>().save(
      Loan(
        id: 0,
        readerId: v['readerId'] as int,
        bookId: v['bookId'] as int,
        days: int.parse(v['days'] as String),
      ),
      isNew: true,
    );
    return SaveResult.success(saved.id);
  },
);

Widget myLoanList(ListQuery query) => EntityListScreen<Loan>(
  title: 'Мои выдачи',
  query: query,
  searchLabel: 'Поиск',
  itemTitle: (l) => l.bookTitle,
  canEdit: false,
  editPermission: Permission.manageLoans,
  filters: [
    FilterSpec.dropdown(
      'status',
      'Состояние',
      (c) => const [
        ('active', 'Активна'),
        ('overdue', 'Просрочена'),
        ('returned', 'Возвращена'),
      ],
    ),
  ],
  columns:
      (context) => [
        TableColumnSpec(label: 'Книга', build: (l) => Text(l.bookTitle)),
        TableColumnSpec(
          label: 'Выдана',
          sortField: 'issuedAt',
          build: (l) => Text(_date(l.issuedAt)),
        ),
        TableColumnSpec(
          label: 'Вернуть до',
          sortField: 'dueAt',
          build: (l) => Text(_date(l.dueAt)),
        ),
        TableColumnSpec(label: 'Состояние', build: (l) => Text(l.statusLabel)),
      ],
);

Widget myLoanDetail(int? id) => EntityDetailScreen<Loan>(
  basePath: '/my-loans',
  id: id,
  title: 'Моя выдача',
  heading: (l) => l.bookTitle,
  canEdit: false,
  rows:
      (context, l) => [
        DetailRow('Выдана', _date(l.issuedAt)),
        DetailRow('Вернуть до', _date(l.dueAt)),
        DetailRow('Возвращена', _date(l.returnedAt)),
        DetailRow('Состояние', l.statusLabel),
      ],
);
