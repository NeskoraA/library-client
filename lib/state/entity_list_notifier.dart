import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/entity.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import '../repositories/repository.dart';
import 'load_status.dart';

class EntityListNotifier<T extends Entity<T>> extends ChangeNotifier {
  final Repository<T> _repository;
  final VoidCallback? onDataChanged;
  final VoidCallback? onRecovered;
  Timer? _retryTimer;

  EntityListNotifier(this._repository, {this.onDataChanged, this.onRecovered});

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  ListQuery? _query;
  PageResult<T> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  ListQuery? get query => _query;
  PageResult<T> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    final query = _query;
    if (query == null) return;
    _retryTimer?.cancel();
    final hadError = _status == LoadStatus.error;
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _result = await _repository.find(query);
      _status = LoadStatus.success;
      if (hadError) onRecovered?.call();
    } on RequestCancelledException {
      return;
    } on ApiException catch (e) {
      _error = 'Не удалось загрузить список: $e';
      _status = LoadStatus.error;
      if (e is NetworkException) {
        _retryTimer = Timer(const Duration(seconds: 5), load);
      }
    }
    notifyListeners();
  }

  Future<void> applyQuery(ListQuery next) async {
    if (next == _query && _status != LoadStatus.idle) return;
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  Future<void> _changed() async {
    onDataChanged?.call();
    await load();
  }

  Future<void> deleteSelected() async {
    await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await _changed();
  }

  Future<void> softDelete(int id) async {
    await _repository.softDelete(id);
    _selected.remove(id);
    await _changed();
  }

  Future<void> hardDelete(int id) async {
    await _repository.hardDelete(id);
    _selected.remove(id);
    await _changed();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await _changed();
  }

  Future<T> save(T item, {required bool isNew}) async {
    final saved =
        isNew ? await _repository.create(item) : await _repository.update(item);
    await _changed();
    return saved;
  }

  Future<T?> findById(int id) => _repository.findById(id);

  Future<int> count(Map<String, String> filters) => _repository.count(filters);

  Future<void> runAction(Future<void> Function() action) async {
    await action();
    await _changed();
  }
}
