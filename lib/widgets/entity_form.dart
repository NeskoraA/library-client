import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exceptions.dart';
import '../validation/validators.dart';
import 'status_views.dart';

typedef FormValues = Map<String, Object?>;

sealed class FieldSpec {
  final String key;
  final String label;

  const FieldSpec(this.key, this.label);
}

class TextFieldSpec extends FieldSpec {
  final Validator? validator;
  final String? Function(FormValues values)? crossCheck;
  final bool numeric;
  final int maxLines;
  final String? hint;

  const TextFieldSpec(
    super.key,
    super.label, {
    this.validator,
    this.crossCheck,
    this.numeric = false,
    this.maxLines = 1,
    this.hint,
  });
}

class DropdownFieldSpec extends FieldSpec {
  final List<(int, String)> options;
  final String? Function(int? value)? validator;

  const DropdownFieldSpec(
    super.key,
    super.label, {
    required this.options,
    this.validator,
  });
}

class MultiSelectFieldSpec extends FieldSpec {
  final List<(int, String)> options;
  final String? Function(List<int>? value)? validator;

  const MultiSelectFieldSpec(
    super.key,
    super.label, {
    required this.options,
    this.validator,
  });
}

class GroupFieldSpec extends FieldSpec {
  final List<FieldSpec> children;

  const GroupFieldSpec(String label, this.children) : super('', label);
}

class SaveResult {
  final int? id;
  final Map<String, String> errors;

  const SaveResult.success(int this.id) : errors = const {};
  const SaveResult.failed(this.errors) : id = null;
}

final unsavedChanges = ValueNotifier<bool>(false);

Future<bool> confirmLeave(BuildContext context) async {
  final leave = await confirmAction(
    context,
    'Несохранённые изменения',
    'В форме есть несохранённые изменения. Уйти без сохранения?',
    confirmLabel: 'Уйти',
  );
  if (leave) unsavedChanges.value = false;
  return leave;
}

class EntityFormScreen extends StatefulWidget {
  final String basePath;
  final int? id;
  final String title;
  final Future<FormValues?> Function(BuildContext context) loadValues;
  final List<FieldSpec> Function(BuildContext context, FormValues values)
  buildFields;
  final FormValues Function(BuildContext context, FormValues values)? normalize;
  final Future<SaveResult> Function(BuildContext context, FormValues values)
  onSave;

  const EntityFormScreen({
    super.key,
    required this.basePath,
    required this.id,
    required this.title,
    required this.loadValues,
    required this.buildFields,
    required this.onSave,
    this.normalize,
  });

  @override
  State<EntityFormScreen> createState() => _EntityFormScreenState();
}

class _EntityFormScreenState extends State<EntityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  FormValues? _values;
  String _initial = '';
  bool _loaded = false;
  bool _saving = false;
  Map<String, String> _errors = {};
  Set<String> _fieldKeys = {};

  String get _backLocation =>
      widget.id == null ? widget.basePath : '${widget.basePath}/${widget.id}';

  @override
  void initState() {
    super.initState();
    widget.loadValues(context).then((values) {
      if (!mounted) return;
      setState(() {
        _values = values;
        _initial = jsonEncode(values);
        _loaded = true;
      });
    });
  }

  @override
  void dispose() {
    unsavedChanges.value = false;
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(String key) => _controllers.putIfAbsent(
    key,
    () => TextEditingController(text: _values![key] as String? ?? ''),
  );

  void _changed(String key, Object? value) {
    setState(() {
      _values![key] = value;
      _errors.remove(key);
      if (widget.normalize != null) {
        _values = widget.normalize!(context, _values!);
      }
    });
    unsavedChanges.value = jsonEncode(_values) != _initial;
  }

  Future<void> _submit() async {
    _errors = {};
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final result = await widget.onSave(context, {..._values!});
      if (!mounted) return;
      if (result.errors.isNotEmpty) {
        _showFieldErrors(result.errors, null);
        return;
      }
      unsavedChanges.value = false;
      context.go('${widget.basePath}/${result.id}');
    } on ValidationException catch (e) {
      _showFieldErrors(e.errors, e.message);
    } on ApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showFieldErrors(Map<String, String> errors, String? message) {
    if (!mounted) return;
    final keys = _fieldKeys;
    final other = {
      for (final e in errors.entries)
        if (!keys.contains(e.key)) e.key: e.value,
    };
    setState(() => _errors = {...errors});
    _formKey.currentState!.validate();
    if (other.isNotEmpty) {
      _showMessage([message ?? 'Ошибка', ...other.values].join(': '));
    }
  }

  Set<String> _keysOf(List<FieldSpec> fields) => {
    for (final f in fields)
      ...(f is GroupFieldSpec ? _keysOf(f.children) : {f.key}),
  };

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: unsavedChanges,
      builder:
          (context, dirty, child) => PopScope(
            canPop: !dirty,
            onPopInvokedWithResult: (didPop, _) async {
              if (didPop) return;
              if (await confirmLeave(context) && context.mounted) {
                context.go(_backLocation);
              }
            },
            child: child!,
          ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            tooltip: 'Назад',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(_backLocation),
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (!_loaded) return const LoadingView();
    if (_values == null) {
      return const Center(child: Text('Запись не найдена'));
    }
    final fields = widget.buildFields(context, _values!);
    _fieldKeys = _keysOf(fields);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final f in fields) _buildField(f),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => context.go(_backLocation),
                      child: const Text('Отмена'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: const Icon(Icons.save),
                      label: Text(widget.id == null ? 'Создать' : 'Сохранить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(FieldSpec spec) {
    final field = switch (spec) {
      TextFieldSpec() => TextFormField(
        controller: _controller(spec.key),
        keyboardType: spec.numeric ? TextInputType.number : null,
        maxLines: spec.maxLines,
        decoration: InputDecoration(
          labelText: spec.label,
          hintText: spec.hint,
          border: const OutlineInputBorder(),
        ),
        validator:
            (v) =>
                _errors[spec.key] ??
                spec.validator?.call(v) ??
                spec.crossCheck?.call(_values!),
        onChanged: (v) => _changed(spec.key, v),
      ),
      DropdownFieldSpec() => DropdownButtonFormField<int>(
        key: ValueKey('${spec.key}:${spec.options.map((o) => o.$1).join(',')}'),
        value:
            spec.options.any((o) => o.$1 == _values![spec.key])
                ? _values![spec.key] as int
                : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: spec.label,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final (id, name) in spec.options)
            DropdownMenuItem(value: id, child: Text(name)),
        ],
        validator: (v) => _errors[spec.key] ?? spec.validator?.call(v),
        onChanged: (v) => _changed(spec.key, v),
      ),
      MultiSelectFieldSpec() => FormField<List<int>>(
        key: ValueKey('${spec.key}:${spec.options.map((o) => o.$1).join(',')}'),
        initialValue: _values![spec.key] as List<int>,
        validator:
            (_) =>
                _errors[spec.key] ??
                spec.validator?.call(_values![spec.key] as List<int>),
        builder: (field) {
          final selected = _values![spec.key] as List<int>;
          return InputDecorator(
            decoration: InputDecoration(
              labelText: spec.label,
              border: const OutlineInputBorder(),
              errorText: field.errorText,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (id, name) in spec.options)
                  FilterChip(
                    label: Text(name),
                    selected: selected.contains(id),
                    onSelected: (_) {
                      final next = [...selected];
                      next.contains(id) ? next.remove(id) : next.add(id);
                      field.didChange(next);
                      _changed(spec.key, next);
                    },
                  ),
              ],
            ),
          );
        },
      ),
      GroupFieldSpec() => InputDecorator(
        decoration: InputDecoration(
          labelText: spec.label,
          border: const OutlineInputBorder(),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final c in spec.children) _buildField(c)],
          ),
        ),
      ),
    };
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: field);
  }
}
