import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shareeat/features/food_listing/data/models/food_model.dart';

class FoodRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _foods => _db.collection('foods');

  final now = Timestamp.fromDate(DateTime.now());
  Stream<List<FoodModel>> watchAvailableFoods() {
    return _foods
        .where('status', isEqualTo: 'available')
        .where('quantityAvailable', isGreaterThan: 0)
        .where('expiryDate', isGreaterThanOrEqualTo: now)
        .orderBy('expiryDate')
        .orderBy('quantityAvailable', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(FoodModel.fromDoc).toList());
  }

  Stream<List<FoodModel>> watchMyFoods(String ownerId) {
    return _foods
        .where('ownerId', isEqualTo: ownerId)
        .where('expiryDate', isGreaterThanOrEqualTo: now)
        .orderBy('expiryDate')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(FoodModel.fromDoc).toList());
  }

  
  Future<void> addFood(FoodModel food) async {
    await _foods.add(food.toCreateJson());
  }

  
  Future<void> updateFood(FoodModel food) async {
    await _foods.doc(food.id).update(food.toUpdateJson());
  }

  Future<void> deleteFood(String foodId) async {
  await _foods.doc(foodId).delete();
}

}
