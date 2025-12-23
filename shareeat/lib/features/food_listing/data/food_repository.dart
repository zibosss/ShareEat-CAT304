import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shareeat/features/food_listing/data/models/food_model.dart'; // ✅ Ensure path is correct

class FoodRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _foods => _db.collection('foods');

  /// Real-time feed (Hides items with 0 quantity)
  Stream<List<FoodModel>> watchAvailableFoods() {
    return _foods
        .where('status', isEqualTo: 'available')
        
        // ✅ NEW FILTER: Only show food with quantity > 0
        .where('quantityAvailable', isGreaterThan: 0) 
        
        // ⚠️ FIRESTORE RULE: 
        // When using a range filter (> 0), you must order by that field first.
        .orderBy('quantityAvailable', descending: true) 
        .orderBy('createdAt', descending: true)
        
        .snapshots()
        .map((snap) => snap.docs.map(FoodModel.fromDoc).toList());
  }

  /// Add new food
  Future<void> addFood(FoodModel food) async {
    await _foods.add(food.toJson());
  }
}