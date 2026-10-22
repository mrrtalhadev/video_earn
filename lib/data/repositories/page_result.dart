import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';

/// One page of a Firestore query plus the cursor for the next page.
class PageResult<T> {
  const PageResult({required this.items, required this.cursor, required this.hasMore});

  const PageResult.empty() : items = const [], cursor = null, hasMore = false;

  final List<T> items;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

typedef JsonQuery = Query<Map<String, dynamic>>;
typedef JsonDoc = DocumentSnapshot<Map<String, dynamic>>;

/// Runs [query] with cursor pagination and maps each doc with [map].
Future<PageResult<T>> fetchPage<T>(
  JsonQuery query,
  T Function(JsonDoc doc) map, {
  JsonDoc? startAfter,
  int pageSize = AppConstants.pageSize,
}) async {
  var q = query.limit(pageSize);
  if (startAfter != null) q = q.startAfterDocument(startAfter);
  final snap = await q.get();
  return PageResult(
    items: snap.docs.map(map).toList(),
    cursor: snap.docs.isEmpty ? startAfter : snap.docs.last,
    hasMore: snap.docs.length == pageSize,
  );
}

extension WriteTimeout<T> on Future<T> {
  /// Money/order writes must never hang silently.
  Future<T> withWriteTimeout() => timeout(AppConstants.writeTimeout);
}
