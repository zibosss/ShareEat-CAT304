// ignore_for_file: use_build_context_synchronously

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:shareeat/features/report/data/report_repository.dart';
import 'package:shareeat/features/report/data/models/report_model.dart';
import 'package:shareeat/features/report/data/analytics_repository.dart';
import 'package:shareeat/features/user_registration/presentation/profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const Color purple = Color(0xFF7A2B93);

  final ReportRepository _reportRepo = ReportRepository();
  final AnalyticsRepository _analyticsRepo = AnalyticsRepository();

  int _selectedIndex = 0;
  String _statusFilter = 'pending';

  int _trendDays = 7; // 7 or 30

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _adminAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _reportsTab(),
          _analyticsTab(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 65,
        decoration: const BoxDecoration(color: purple),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navButton(Icons.report, 0),
            _navButton(Icons.analytics, 1),
            _navButton(Icons.person, 2),
          ],
        ),
      ),
    );
  }

  // =========================
  // ADMIN HEADER
  // =========================
  AppBar _adminAppBar() {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.email?.split('@').first ?? 'admin';

    return AppBar(
      backgroundColor: purple,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.logout, color: Colors.white),
        onPressed: _confirmLogout,
      ),
      title: const Text(
        "ShareEat",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            children: [
              Text(
                username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 22, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================
  // REPORTS TAB
  // =========================
  Widget _reportsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Text("Status",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _statusFilter,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(
                      value: 'under_review', child: Text('Under review')),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                ],
                onChanged: (v) => setState(() {
                  _statusFilter = v ?? 'pending';
                }),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ReportModel>>(
            stream: _reportRepo.streamReports(status: _statusFilter),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final reports = snapshot.data!;
              if (reports.isEmpty) {
                return const Center(child: Text("No reports found"));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final r = reports[i];
                  return InkWell(
                    onTap: () => _openReportDetail(r),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: purple.withOpacity(0.15),
                            child: const Icon(Icons.report, color: purple),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.reportType,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text("Against: ${r.reportedUsername}"),
                                Text(
                                  "By: ${r.reporterName}",
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================
  // REPORT DETAIL
  // =========================
  Future<void> _openReportDetail(ReportModel r) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.reportType,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Reported: ${r.reportedUsername}"),
              Text("Reporter: ${r.reporterName}"),
              const SizedBox(height: 12),
              Text(r.description),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // ANALYTICS TAB
  // =========================
  Widget _analyticsTab() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        _analyticsRepo.getTotalFoodsCount(),
        _analyticsRepo.getAvailableFoodsCount(),
        _analyticsRepo.getFoodHalalCounts(),
        _analyticsRepo.getFoodTypeCounts(fieldName: 'category'),
        _analyticsRepo.getFoodsExpiringSoon(days: 3),
        _analyticsRepo.getFoodsAddedTrend(days: _trendDays),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Analytics error: ${snapshot.error}"));
        }
        if (!snapshot.hasData) {
          return const Center(child: Text("No analytics data."));
        }

        final totalFoods = snapshot.data![0] as int;
        final availableFoods = snapshot.data![1] as int;
        final halalCounts = snapshot.data![2] as Map<String, int>;
        final topTypes = snapshot.data![3] as List<Map<String, dynamic>>;
        final expiringSoon = snapshot.data![4] as List<Map<String, dynamic>>;
        final trend = snapshot.data![5] as List<Map<String, dynamic>>;

        final halal = halalCounts['halal'] ?? 0;
        final nonHalal = halalCounts['nonHalal'] ?? 0;

        // NOTE: "Not available" here means not available or expired (estimate).
        final notAvailableOrExpired = math.max(0, totalFoods - availableFoods);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Food Analytics",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // KPI cards
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _kpiCard("Total Foods", totalFoods),
                _kpiCard("Available Foods", availableFoods),
                _kpiCard("Halal", halal),
                _kpiCard("Non-halal", nonHalal),
              ],
            ),

            const SizedBox(height: 16),

            // Donut charts (Halal + Availability)
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 700; // phone / small screen

                if (isNarrow) {
                  return Column(
                    children: [
                      _donutCard(
                        title: "Halal vs Non-halal",
                        aLabel: "Halal",
                        aValue: halal,
                        bLabel: "Non-halal",
                        bValue: nonHalal,
                      ),
                      const SizedBox(height: 12),
                      _donutCard(
                        title: "Availability",
                        aLabel: "Available",
                        aValue: availableFoods,
                        bLabel: "Not avail/expired",
                        bValue: notAvailableOrExpired,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _donutCard(
                        title: "Halal vs Non-halal",
                        aLabel: "Halal",
                        aValue: halal,
                        bLabel: "Non-halal",
                        bValue: nonHalal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _donutCard(
                        title: "Availability",
                        aLabel: "Available",
                        aValue: availableFoods,
                        bLabel: "Not avail/expired",
                        bValue: notAvailableOrExpired,
                      ),
                    ),
                  ],
                );
              },
            ),


            const SizedBox(height: 16),

            // Trend bar chart
            _foodsTrendCard(trend),

            const SizedBox(height: 24),

            const Text(
              "Top Food Types",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (topTypes.isEmpty)
              const Text(
                "No type/category data found. (If you don’t use category, it’s okay to ignore this.)",
              ),
            ...topTypes.map((e) => Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    title: Text(e['type'].toString()),
                    trailing: Text(
                      e['total'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )),

            const SizedBox(height: 24),

            const Text(
              "Expiring Soon (≤ 3 days)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (expiringSoon.isEmpty) const Text("No foods expiring soon 🎉"),
            ...expiringSoon.map((e) => Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    title: Text(e['title'].toString()),
                    subtitle: Text("Qty: ${e['quantityAvailable']}"),
                  ),
                )),
          ],
        );
      },
    );
  }

  // =========================
  // TREND CARD
  // =========================
  Widget _foodsTrendCard(List<Map<String, dynamic>> trend) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Foods Added (Trend)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F1FA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      _trendChip("7D", isActive: _trendDays == 7, onTap: () {
                        setState(() => _trendDays = 7);
                      }),
                      _trendChip("30D", isActive: _trendDays == 30, onTap: () {
                        setState(() => _trendDays = 30);
                      }),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (trend.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text("No trend data."),
              )
            else
              _barChart(trend),
          ],
        ),
      ),
    );
  }

  Widget _barChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxVal = data
        .map((e) => (e['total'] as int?) ?? 0)
        .fold<int>(0, (a, b) => a > b ? a : b);

    String shortLabel(String yyyyMmDd) => yyyyMmDd.split('-').last;

    // ✅ auto aspect ratio based on number of bars (more bars => wider chart => less tall)
    final barsCount = data.length;
    final aspect = (barsCount <= 7)
        ? 2.2
        : (barsCount <= 14)
            ? 2.6
            : 3.2;

    // Reserve space for X labels + bottom caption.
    const xLabelSpace = 18.0;
    const captionSpace = 18.0;
    const topValueSpace = 16.0;

    return AspectRatio(
      aspectRatio: aspect,
      child: LayoutBuilder(
        builder: (context, c) {
          // ✅ real drawable height for bars (prevents overflow on emulator)
          final barsAreaHeight =
              (c.maxHeight - xLabelSpace - captionSpace - topValueSpace)
                  .clamp(40.0, double.infinity);

          return Column(
            children: [
              // Bars + value labels
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(data.length, (i) {
                      final total = (data[i]['total'] as int?) ?? 0;
                      final ratio = maxVal == 0 ? 0.0 : total / maxVal;
                      final barH = (ratio * barsAreaHeight).clamp(2.0, barsAreaHeight);

                      final showLabel = _trendDays == 7
                          ? true
                          : (i % 5 == 0 || i == data.length - 1);

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // value label (only show if space & useful)
                              SizedBox(
                                height: topValueSpace,
                                child: (_trendDays == 7 && total > 0)
                                    ? FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "$total",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),

                              // bar
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                height: barH,
                                decoration: BoxDecoration(
                                  color: purple,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),

                              // x label
                              SizedBox(
                                height: xLabelSpace,
                                child: Center(
                                  child: showLabel
                                      ? Text(
                                          shortLabel(data[i]['day'].toString()),
                                          style: const TextStyle(fontSize: 10),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // bottom caption
              SizedBox(
                height: captionSpace,
                child: Center(
                  child: Text(
                    _trendDays == 7
                        ? "Last 7 days (day of month)"
                        : "Last 30 days (labels every 5 days)",
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }


  Widget _trendChip(String label,
      {required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? purple : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : purple,
          ),
        ),
      ),
    );
  }

  // =========================
  // KPI CARD
  // =========================
  Widget _kpiCard(String title, int value) {
    return SizedBox(
      width: 160,
      child: Card(
        color: const Color(0xFFF6F1FA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              Text(
                "$value",
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // DONUT CARD (custom painter)
  // =========================
  Widget _donutCard({
    required String title,
    required String aLabel,
    required int aValue,
    required String bLabel,
    required int bValue,
  }) {
    return Card(
      color: const Color(0xFFF6F1FA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 140, // just a “max width”, AspectRatio keeps it square
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(
                      painter: _DonutPainter(
                        aValue: aValue,
                        bValue: bValue,
                        aColor: purple,
                        bColor: Colors.grey.shade400,
                      ),
                      child: Center(
                        child: Text(
                          "${aValue + bValue}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _legendRow(aLabel, aValue, purple),
                      const SizedBox(height: 8),
                      _legendRow(bLabel, bValue, Colors.grey.shade400),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        Text("$value",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  // =========================
  // HELPERS
  // =========================
  Widget _navButton(IconData icon, int index) {
    final active = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Icon(
        icon,
        size: 28,
        color: active ? Colors.white : Colors.white70,
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Log out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Log out"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, "/login");
    }
  }
}

// ----------------------------
// Donut Painter
// ----------------------------
class _DonutPainter extends CustomPainter {
  final int aValue;
  final int bValue;
  final Color aColor;
  final Color bColor;

  _DonutPainter({
    required this.aValue,
    required this.bValue,
    required this.aColor,
    required this.bColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = aValue + bValue;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final paintA = Paint()
      ..color = aColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;

    final paintB = Paint()
      ..color = bColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;

    // background ring
    canvas.drawCircle(center, radius - 13, paintB);

    if (total == 0) return;

    final sweepA = (aValue / total) * (2 * math.pi);
    const start = -math.pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 13),
      start,
      sweepA,
      false,
      paintA,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
