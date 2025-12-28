import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ----------------------------
  // FOOD ANALYTICS
  // ----------------------------

  /// Total food items in foods collection (all)
  Future<int> getTotalFoodsCount() async {
    final snap = await _db.collection('foods').get();
    return snap.size;
  }

  /// Total food items that are still available (quantityAvailable > 0) and not expired.
  Future<int> getAvailableFoodsCount() async {
  final now = DateTime.now();

  // Only ONE inequality in Firestore (expiryDate)
  final snap = await _db
      .collection('foods')
      .where('expiryDate', isGreaterThan: Timestamp.fromDate(now))
      .get();

  // Filter quantityAvailable in Dart
  int count = 0;
  for (final d in snap.docs) {
    final data = d.data();
    final qty = (data['quantityAvailable'] ?? 0) as num;
    if (qty > 0) count++;
  }
  return count;
}

  /// Halal vs Non-halal counts (only available + not expired)
  Future<Map<String, int>> getFoodHalalCounts() async {
  final now = DateTime.now();

  // Only ONE inequality in Firestore
  final snap = await _db
      .collection('foods')
      .where('expiryDate', isGreaterThan: Timestamp.fromDate(now))
      .get();

  int halal = 0;
  int nonHalal = 0;

  for (final d in snap.docs) {
    final data = d.data();
    final qty = (data['quantityAvailable'] ?? 0) as num;
    if (qty <= 0) continue;

    final isHalal = data['isHalal'] == true;
    if (isHalal) {
      halal++;
    } else {
      nonHalal++;
    }
  }

  return {
    'halal': halal,
    'nonHalal': nonHalal,
    'total': halal + nonHalal,
  };
}


  /// "Types of food" = group by a field name.
  /// Use fieldName like: 'category' OR 'foodType' OR 'title'
  Future<List<Map<String, dynamic>>> getFoodTypeCounts({
  String fieldName = 'category',
  int topN = 8,
}) async {
  final now = DateTime.now();

  // Only ONE inequality in Firestore
  final snap = await _db
      .collection('foods')
      .where('expiryDate', isGreaterThan: Timestamp.fromDate(now))
      .get();

  final Map<String, int> counts = {};

  for (final d in snap.docs) {
    final data = d.data();
    final qty = (data['quantityAvailable'] ?? 0) as num;
    if (qty <= 0) continue;

    final raw = data[fieldName];
    final key = (raw == null || raw.toString().trim().isEmpty)
        ? 'Uncategorized'
        : raw.toString().trim();

    counts[key] = (counts[key] ?? 0) + 1;
  }

  final list = counts.entries
      .map((e) => {'type': e.key, 'total': e.value})
      .toList()
    ..sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));

  return list.take(topN).toList();
}

  /// Foods expiring soon (within N days), still available
  Future<List<Map<String, dynamic>>> getFoodsExpiringSoon({int days = 3}) async {
  final now = DateTime.now();
  final end = now.add(Duration(days: days));

  // ✅ Only ONE inequality (expiryDate <= end)
  final snap = await _db
      .collection('foods')
      .where('expiryDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
      .get();

  final List<Map<String, dynamic>> result = [];

  for (final d in snap.docs) {
    final data = d.data();

    // ✅ Filter quantityAvailable in Dart (avoid 2nd inequality in Firestore)
    final qty = (data['quantityAvailable'] ?? 0) as num;
    if (qty <= 0) continue;

    final ts = data['expiryDate'] as Timestamp?;
    result.add({
      'id': d.id,
      'title': (data['title'] ?? data['name'] ?? 'Food').toString(),
      'expiry': ts?.toDate(),
      'quantityAvailable': qty,
    });
  }

  return result;
}

  /// Foods added per day for last [days] (7 or 30).
  /// Requires foods.createdAt (Timestamp).
  Future<List<Map<String, dynamic>>> getFoodsAddedTrend({int days = 7}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));

    final snap = await _db
        .collection('foods')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();

    final Map<String, int> counts = {};
    for (int i = 0; i < days; i++) {
      final d = start.add(Duration(days: i));
      final key =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      counts[key] = 0;
    }

    for (final doc in snap.docs) {
      final data = doc.data();
      final ts = data['createdAt'];
      if (ts is! Timestamp) continue;

      final d = ts.toDate();
      final key =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      if (counts.containsKey(key)) {
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }

    return counts.entries
        .map((e) => {'day': e.key, 'total': e.value})
        .toList();
  }
}
