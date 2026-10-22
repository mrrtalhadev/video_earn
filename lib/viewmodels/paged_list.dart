import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../data/repositories/page_result.dart';

typedef PageFetcher<T> = Future<PageResult<T>> Function(JsonDoc? startAfter);

/// Cursor-paginated list state with its own loading/error flags, so one
/// ViewModel can own several lists (e.g. Pending / Approved / Rejected tabs).
class PagedList<T> {
  PagedList(this._fetch, this._onChanged);

  final PageFetcher<T> _fetch;
  final VoidCallback _onChanged;

  final List<T> items = [];
  JsonDoc? _cursor;
  bool hasMore = true;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool loaded = false;
  String? error;
  int _generation = 0;

  bool get isEmpty => loaded && items.isEmpty && error == null;

  Future<void> refresh() async {
    final gen = ++_generation;
    isLoading = true;
    error = null;
    _onChanged();
    try {
      final page = await _fetch(null);
      if (gen != _generation) return;
      items
        ..clear()
        ..addAll(page.items);
      _cursor = page.cursor;
      hasMore = page.hasMore;
      loaded = true;
    } catch (e) {
      if (gen != _generation) return;
      debugPrint('PagedList refresh failed: $e');
      error = AppException.from(e).message;
    } finally {
      if (gen == _generation) {
        isLoading = false;
        _onChanged();
      }
    }
  }

  /// Loads the first page once.
  Future<void> ensureLoaded() async {
    if (!loaded && !isLoading) await refresh();
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoading || isLoadingMore) return;
    final gen = _generation;
    isLoadingMore = true;
    _onChanged();
    try {
      final page = await _fetch(_cursor);
      if (gen != _generation) return;
      items.addAll(page.items);
      _cursor = page.cursor;
      hasMore = page.hasMore;
    } catch (e) {
      if (gen != _generation) return;
      debugPrint('PagedList loadMore failed: $e');
      error = AppException.from(e).message;
    } finally {
      if (gen == _generation) {
        isLoadingMore = false;
        _onChanged();
      }
    }
  }

  /// Removes an item locally (e.g. after approve/reject moved it to another tab).
  void remove(bool Function(T item) test) {
    items.removeWhere(test);
    _onChanged();
  }

  /// Marks the list stale so the next [ensureLoaded] refetches.
  void invalidate() => loaded = false;
}
