import 'page_result.dart';

class ListQuery {
  final String path;
  final String defaultSort;
  final String search;
  final Map<String, String> filters;
  final String? _sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  static const _reserved = {'search', 'sort', 'page', 'size', 'deleted'};

  const ListQuery({
    required this.path,
    required this.defaultSort,
    this.search = '',
    this.filters = const {},
    String? sortField,
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  }) : _sortField = sortField;

  String get sortField => _sortField ?? defaultSort;

  int? intFilter(String key) => int.tryParse(filters[key] ?? '');

  ListQuery copyWith({
    String? search,
    Map<String, String>? filters,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return ListQuery(
      path: path,
      defaultSort: defaultSort,
      search: search ?? this.search,
      filters: filters ?? this.filters,
      sortField: sortField ?? _sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  ListQuery withFilter(String key, String? value) {
    final next = {...filters};
    if (value == null || value.trim().isEmpty) {
      next.remove(key);
    } else {
      next[key] = value.trim();
    }
    return copyWith(filters: next);
  }

  factory ListQuery.fromParams(
    String path,
    String defaultSort,
    Map<String, String> p,
  ) {
    final sort = (p['sort'] ?? '').split(',');
    final size = int.tryParse(p['size'] ?? '') ?? 10;
    final page = int.tryParse(p['page'] ?? '') ?? 1;
    return ListQuery(
      path: path,
      defaultSort: defaultSort,
      search: p['search'] ?? '',
      filters: {
        for (final e in p.entries)
          if (!_reserved.contains(e.key) && e.value.isNotEmpty) e.key: e.value,
      },
      sortField: sort[0].isEmpty ? null : sort[0],
      sortAscending: sort.length < 2 || sort[1] != 'desc',
      page: page < 1 ? 1 : page,
      size: pageSizes.contains(size) ? size : 10,
      includeDeleted: p['deleted'] == 'true',
    );
  }

  String toLocation() {
    final keys = filters.keys.toList()..sort();
    final parts = <String>[
      if (search.isNotEmpty) 'search=${Uri.encodeQueryComponent(search)}',
      for (final k in keys) '$k=${Uri.encodeQueryComponent(filters[k]!)}',
      if (sortField != defaultSort || !sortAscending)
        'sort=$sortField,${sortAscending ? 'asc' : 'desc'}',
      if (page != 1) 'page=$page',
      if (size != 10) 'size=$size',
      if (includeDeleted) 'deleted=true',
    ];
    return parts.isEmpty ? path : '$path?${parts.join('&')}';
  }

  @override
  bool operator ==(Object other) =>
      other is ListQuery && other.toLocation() == toLocation();

  @override
  int get hashCode => toLocation().hashCode;
}
