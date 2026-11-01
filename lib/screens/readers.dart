import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/list_query.dart';
import '../models/reader.dart';
import '../state/entity_list_notifier.dart';
import '../state/permissions.dart';
import '../validation/validators.dart';
import '../widgets/entity_detail_screen.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_list_screen.dart';
import '../widgets/entity_table.dart';

String _date(DateTime? d) => d == null ? 'нет' : formatDate(d.toLocal());

Widget readerList(ListQuery query) => EntityListScreen<Reader>(
  title: 'Читатели',
  query: query,
  searchLabel: 'Поиск по ФИО, почте или телефону',
  itemTitle: (r) => r.fullName,
  editPermission: Permission.manageReaders,
  columns:
      (context) => [
        TableColumnSpec(
          label: 'ФИО',
          sortField: 'fullName',
          build: (r) => Text(r.fullName),
        ),
        TableColumnSpec(
          label: 'Почта',
          sortField: 'email',
          build: (r) => Text(r.email),
        ),
        TableColumnSpec(label: 'Телефон', build: (r) => Text(r.phone)),
        TableColumnSpec(
          label: 'Билет',
          build: (r) => Text(r.card?.number ?? 'нет'),
        ),
      ],
);

Widget readerDetail(int? id) => EntityDetailScreen<Reader>(
  basePath: '/readers',
  id: id,
  title: 'Карточка читателя',
  heading: (r) => r.fullName,
  editPermission: Permission.manageReaders,
  rows:
      (context, r) => [
        DetailRow('Почта', r.email),
        DetailRow('Телефон', r.phone),
        DetailRow('Номер билета', r.card?.number ?? 'нет'),
        DetailRow('Выдан', _date(r.card?.issuedAt)),
        DetailRow('Действует до', _date(r.card?.expiresAt)),
        DetailRow(
          'Статус билета',
          r.card == null
              ? 'нет билета'
              : (r.card!.isActive ? 'действует' : 'просрочен'),
        ),
        DetailRow.links('Выдачи', [
          ('Открыть выдачи', '/loans?readerId=${r.id}'),
        ]),
      ],
);

Widget readerForm(int? id) => EntityFormScreen(
  basePath: '/readers',
  id: id,
  title: id == null ? 'Новый читатель' : 'Изменение читателя',
  loadValues: (context) async {
    if (id == null) return {'fullName': '', 'email': '', 'phone': ''};
    final r = await context.read<EntityListNotifier<Reader>>().findById(id);
    if (r == null) return null;
    return {'fullName': r.fullName, 'email': r.email, 'phone': r.phone};
  },
  buildFields:
      (context, values) => [
        TextFieldSpec(
          'fullName',
          'ФИО (Фамилия И. О.)',
          validator: combine([requiredField, maxLength(100), personName]),
        ),
        TextFieldSpec(
          'email',
          'Электронная почта',
          validator: combine([requiredField, maxLength(100), email]),
        ),
        TextFieldSpec(
          'phone',
          'Телефон',
          hint: '+7 900 000-00-00',
          validator: combine([requiredField, phone]),
        ),
      ],
  onSave: (context, v) async {
    final saved = await context.read<EntityListNotifier<Reader>>().save(
      Reader(
        id: id ?? 0,
        fullName: (v['fullName'] as String).trim(),
        email: (v['email'] as String).trim(),
        phone: (v['phone'] as String).trim(),
      ),
      isNew: id == null,
    );
    return SaveResult.success(saved.id);
  },
);
