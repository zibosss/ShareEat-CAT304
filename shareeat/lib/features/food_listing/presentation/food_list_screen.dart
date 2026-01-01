import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/food_repository.dart';
import '../data/models/food_model.dart';
import 'booking_detail_screen.dart';
import 'add_food_screen.dart';

enum HalalFilter { all, halal, nonHalal }

enum DateSort { newest, oldest }

class FoodListScreen extends StatefulWidget {
  final String? username;
  final bool isLoadingUser;

  const FoodListScreen({super.key, this.username, this.isLoadingUser = false});

  @override
  State<FoodListScreen> createState() => FoodListScreenState();
}

class FoodListScreenState extends State<FoodListScreen>
    with SingleTickerProviderStateMixin {
  final FoodRepository _foodRepo = FoodRepository();

  late final TabController _tabController;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  HalalFilter _halalFilter = HalalFilter.all;
  DateSort _dateSort = DateSort.newest;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> reloadFoods() async {
    setState(() {});
  }

  void _searchFoods(String query) {
    setState(() => _query = query.trim().toLowerCase());
  }

  bool _matchHalal(FoodModel f) {
    switch (_halalFilter) {
      case HalalFilter.all:
        return true;
      case HalalFilter.halal:
        return f.isHalal == true;
      case HalalFilter.nonHalal:
        return f.isHalal == false;
    }
  }

  bool _matchSearch(FoodModel f) {
    if (_query.isEmpty) return true;
    return f.title.toLowerCase().contains(_query) ||
        f.description.toLowerCase().contains(_query);
  }

  List<FoodModel> _applyFilters(List<FoodModel> foods) {
    final filtered = foods
        .where((f) => _matchSearch(f) && _matchHalal(f))
        .toList();

    filtered.sort((a, b) {
      return _dateSort == DateSort.newest
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt);
    });

    return filtered;
  }

  String _halalLabel(HalalFilter v) {
    switch (v) {
      case HalalFilter.all:
        return 'All';
      case HalalFilter.halal:
        return 'Halal';
      case HalalFilter.nonHalal:
        return 'Non-Halal';
    }
  }

  String _dateLabel(DateSort v) {
    switch (v) {
      case DateSort.newest:
        return 'Newest';
      case DateSort.oldest:
        return 'Oldest';
    }
  }

  void _openFilterSheet() {
    HalalFilter tempHalal = _halalFilter;
    DateSort tempDate = _dateSort;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Halal Status',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: tempHalal == HalalFilter.all,
                        onSelected: (_) =>
                            setSheetState(() => tempHalal = HalalFilter.all),
                      ),
                      ChoiceChip(
                        label: const Text('Halal'),
                        selected: tempHalal == HalalFilter.halal,
                        onSelected: (_) =>
                            setSheetState(() => tempHalal = HalalFilter.halal),
                      ),
                      ChoiceChip(
                        label: const Text('Non-Halal'),
                        selected: tempHalal == HalalFilter.nonHalal,
                        onSelected: (_) => setSheetState(
                          () => tempHalal = HalalFilter.nonHalal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Date Posted',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Newest'),
                        selected: tempDate == DateSort.newest,
                        onSelected: (_) =>
                            setSheetState(() => tempDate = DateSort.newest),
                      ),
                      ChoiceChip(
                        label: const Text('Oldest'),
                        selected: tempDate == DateSort.oldest,
                        onSelected: (_) =>
                            setSheetState(() => tempDate = DateSort.oldest),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              tempHalal = HalalFilter.all;
                              tempDate = DateSort.newest;
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7A2B93),
                          ),
                          onPressed: () {
                            setState(() {
                              _halalFilter = tempHalal;
                              _dateSort = tempDate;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Apply',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chipsText = '${_halalLabel(_halalFilter)} • ${_dateLabel(_dateSort)}';
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),

        // search + filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchFoods,
                    textAlignVertical: TextAlignVertical.center, 
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Search food...",
                      isDense: true, 
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ), 
                      prefixIcon: const Icon(Icons.search),
                      prefixIconConstraints: const BoxConstraints(
                        minHeight: 24,
                        minWidth: 48,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _openFilterSheet,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A2B93).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF7A2B93).withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.filter_list,
                    color: Color(0xFF7A2B93),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // active filter summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.tune, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                chipsText,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ✅ Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 42,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF7A2B93).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF7A2B93).withValues(alpha: 0.25),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: const Color(0xFF7A2B93),
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF7A2B93),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              labelPadding: EdgeInsets.zero,
              indicatorPadding: EdgeInsets.zero,
              tabs: const [
                Tab(text: 'All Foods'),
                Tab(text: 'My Foods'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // ===== TAB 1: ALL FOODS =====
              StreamBuilder<List<FoodModel>>(
                stream: _foodRepo.watchAvailableFoods(),
                builder: (context, snapshot) {
                  return _buildGridFromSnapshot(
                    snapshot: snapshot,
                    isMyFoodsTab: false,
                    uid: uid,
                  );
                },
              ),

              // ===== TAB 2: MY FOODS =====
              if (uid == null)
                const Center(child: Text('Please login to view your foods'))
              else
                StreamBuilder<List<FoodModel>>(
                  stream: _foodRepo.watchMyFoods(uid),
                  builder: (context, snapshot) {
                    return _buildGridFromSnapshot(
                      snapshot: snapshot,
                      isMyFoodsTab: true,
                      uid: uid,
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridFromSnapshot({
    required AsyncSnapshot<List<FoodModel>> snapshot,
    required bool isMyFoodsTab,
    required String? uid,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    final foods = snapshot.data ?? [];
    final filtered = _applyFilters(foods);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.food_bank_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isMyFoodsTab ? 'No foods posted yet' : 'No matching food items',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              isMyFoodsTab
                  ? 'Tap + to add your first food'
                  : 'Try changing filters or search',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: reloadFoods,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.75,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final foodItem = filtered[index];

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingDetailScreen(food: foodItem),
                ),
              );
            },
            child: _FoodCard(
              food: foodItem,
              showEdit: isMyFoodsTab, // ✅ edit only in My Foods tab
              onEdit: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddFoodScreen(food: foodItem),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class _FoodCard extends StatelessWidget {
  final FoodModel food;
  final bool showEdit;
  final VoidCallback? onEdit;

  const _FoodCard({required this.food, this.showEdit = false, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: (food.imageUrl != null && food.imageUrl!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                          child: Image.network(
                            food.imageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return const Center(
                                child: Icon(
                                  Icons.image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Posted: ${dateFormat.format(food.createdAt)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Text(
                      'Expiry: ${dateFormat.format(food.expiryDate)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Qty: ${food.quantityAvailable}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        if (food.isHalal)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Text(
                              'Halal',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ✅ edit button overlay (only in My Foods tab)
        if (showEdit)
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onEdit,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.edit, size: 18, color: Color(0xFF7A2B93)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
