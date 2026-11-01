import '../models/entity.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';

abstract interface class Repository<T extends Entity<T>> {
  Future<PageResult<T>> find(ListQuery query);
  Future<T?> findById(int id);
  Future<List<T>> findAll();
  Future<int> count(Map<String, String> filters);
  Future<T> create(T item);
  Future<T> update(T item);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
