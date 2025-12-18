import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/food_repository.dart';
import '../data/models/food_model.dart';

enum HalalFilter { all, halal, nonHalal }
enum DateSort { newest, oldest }

class FoodListScreen extends StatefulWidget {
  final String? username;
  final bool isLoadingUser;

  const FoodListScreen({
    super.key,
    this.username,
    this.isLoadingUser = false,
  });

  @override
  State<FoodListScreen> createState() => FoodListScreenState();
}

class FoodListScreenState extends State<FoodListScreen> {
  final FoodRepository _foodRepo = FoodRepository();
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  HalalFilter _halalFilter = HalalFilter.all;
  DateSort _dateSort = DateSort.newest;

  void _searchFoods(String query) {
    setState(() => _query = query.trim().toLowerCase());
  }

  bool _matchHalal(FoodModel f) {
    switch (_halalFilter) {
      case HalalFilter.all:
        return true;
      case HalalFilter.halal:
        return f.isHalal;
      case HalalFilter.nonHalal:
        return !f.isHalal;
    }
  }

  bool _matchSearch(FoodModel f) {
    if (_query.isEmpty) return true;
    return f.title.toLowerCase().contains(_query) ||
        f.description.toLowerCase().contains(_query);
  }

  List<FoodModel> _applyFilters(List<FoodModel> foods) {
    final filtered =
        foods.where((f) => _matchSearch(f) && _matchHalal(f)).toList();

    filtered.sort((a, b) => _dateSort == DateSort.newest
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));

    return filtered;
  }

  String _halalLabel(HalalFilter v) =>
      v == HalalFilter.all ? 'All' : v == HalalFilter.halal ? 'Halal' : 'Non-Halal';

  String _dateLabel(DateSort v) =>
      v == DateSort.newest ? 'Newest' : 'Oldest';

  @override
  Widget build(BuildContext context) {
    final chipsText = '${_halalLabel(_halalFilter)} • ${_dateLabel(_dateSort)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),

        /// Greeting
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: widget.isLoadingUser
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hi, ${widget.username ?? ""} 👋",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Ready to share food today?",
                      style:
                          TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 15),

        /// Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.black.withOpacity(0.2)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _searchFoods,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Search food...",
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            chipsText,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),

        const SizedBox(height: 10),

        /// Food grid
        Expanded(
          child: StreamBuilder<List<FoodModel>>(
            stream: _foodRepo.watchAvailableFoods(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final foods = snapshot.data ?? [];
              final filtered = _applyFilters(foods);

              if (filtered.isEmpty) {
                return const Center(
                  child: Text("No food items found"),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.75,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return _FoodCard(food: filtered[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

/// ===============================================================
/// FOOD CARD
/// ===============================================================
class _FoodCard extends StatelessWidget {
  final FoodModel food;

  const _FoodCard({required this.food});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return GestureDetector(
      onTap: () {
        final foodItem = {
          'name': food.title,
          'image': food.imageUrl ?? '',
          'description': food.description,
          'quantity': food.quantityAvailable,
          'posted': dateFormat.format(food.createdAt),
          'expiry': dateFormat.format(food.expiryDate),
          'isHalal': food.isHalal,
        };

        showFoodDetailPopup(context, foodItem);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                    ? Image.network(
                        food.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(Icons.image,
                        size: 50, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                food.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// FOOD DETAIL POPUP
/// ===============================================================
void showFoodDetailPopup(
    BuildContext context, Map<String, dynamic> foodItem) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(foodItem['name']),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(foodItem['description']),
          const SizedBox(height: 10),
          Text('Quantity: ${foodItem['quantity']}'),
          Text('Expiry: ${foodItem['expiry']}'),
          if (foodItem['isHalal'])
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('✔ Halal',
                  style: TextStyle(color: Colors.green)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
