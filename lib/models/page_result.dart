class PageResult<T> {
  final List<T> items;
  final int page;
  final int size;
  final int total;

  const PageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });

  int get totalPages => total == 0 ? 1 : (total / size).ceil();
  bool get hasPrevious => page > 1;
  bool get hasNext => page < totalPages;

  PageResult.empty() : items = <T>[], page = 1, size = 10, total = 0;

  static PageResult<T> of<T>(List<T> rows, int page, int size) {
    final total = rows.length;
    final from = (page - 1) * size;
    final to = (from + size) > total ? total : (from + size);
    final items = from >= total ? <T>[] : rows.sublist(from, to);
    return PageResult(items: items, page: page, size: size, total: total);
  }
}

const pageSizes = [10, 25, 50];
