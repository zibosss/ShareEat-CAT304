import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/food_model.dart';

class FoodRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _foods => _db.collection('foods');

  /// Real-time feed (everyone sees)
  ///
  /// NOTE: This query REQUIRES a composite index because it uses
  /// where(status) + orderBy(createdAt).
  Stream<List<FoodModel>> watchAvailableFoods() {
    return _foods
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(FoodModel.fromDoc).toList());
  }

  /// Add new food
  Future<void> addFood(FoodModel food) async {
    await _foods.add(food.toJson());
  }
}