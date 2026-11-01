import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/entity.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import 'repository.dart';

abstract class ApiRepository<T extends Entity<T>> implements Repository<T> {
  final Dio dio;
  final String path;
  CancelToken? _findToken;

  ApiRepository(this.dio, this.path);

  T fromJson(Map<String, dynamic> json);

  PageResult<T> _parsePage(dynamic data, int fallbackSize) {
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    return PageResult(
      items: readMapList(map['items']).map(fromJson).toList(),
      page: readInt(map['page'], 1),
      size: readInt(map['size'], fallbackSize),
      total: readInt(map['total']),
    );
  }

  @override
  Future<PageResult<T>> find(ListQuery q) => guard(() async {
    _findToken?.cancel();
    final token = _findToken = CancelToken();
    final response = await dio.get(
      path,
      cancelToken: token,
      queryParameters: {
        if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
        ...q.filters,
        'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
        'page': q.page,
        'size': q.size,
        if (q.includeDeleted) 'includeDeleted': true,
      },
    );
    return _parsePage(response.data, q.size);
  });

  @override
  Future<List<T>> findAll() => guard(() async {
    final response = await dio.get(path, queryParameters: {'size': 100});
    return _parsePage(response.data, 100).items;
  });

  @override
  Future<int> count(Map<String, String> filters) => guard(() async {
    final response = await dio.get(
      path,
      queryParameters: {...filters, 'size': 1},
    );
    return _parsePage(response.data, 1).total;
  });

  @override
  Future<T?> findById(int id) async {
    try {
      return await guard(() async {
        final response = await dio.get(
          '$path/$id',
          queryParameters: {'includeDeleted': true},
        );
        return fromJson(response.data as Map<String, dynamic>);
      });
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<T> create(T item) => guard(() async {
    final response = await dio.post(path, data: item.toJson());
    return fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<T> update(T item) => guard(() async {
    final response = await dio.put('$path/${item.id}', data: item.toJson());
    return fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<void> softDelete(int id) => guard(() => dio.delete('$path/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => dio.delete('$path/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) => guard(() => dio.post('$path/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    final response = await dio.post('$path/bulk-delete', data: {'ids': ids});
    return readInt(readMap(response.data)['deleted']);
  });
}
