// lib/features/report/presentation/admin_dashboard.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  // all | pending | rejected | banned
  String _statusFilter = 'all';

  int _trendDays = 7; 

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
    const List<Map<String, String>> statusOptions = [
      {'value': 'all', 'label': 'All'},
      {'value': 'pending', 'label': 'Pending'},
      {'value': 'rejected', 'label': 'Rejected'},
      {'value': 'banned', 'label': 'Banned'},
    ];

    return Column(
      children: [
        // Filter row
        // Filter row (simplified: just "Status" + dropdown)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Text(
                "Status",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: statusOptions
                        .map(
                          (opt) => DropdownMenuItem(
                            value: opt['value'],
                            child: Text(opt['label']!),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      _statusFilter = v ?? 'all';
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // List of reports
        Expanded(
          child: StreamBuilder<List<ReportModel>>(
            stream: _reportRepo.watchReports(status: _statusFilter),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    "Failed to load reports:\n${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final reports = snapshot.data ?? [];
              if (reports.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _statusFilter == 'all'
                          ? "🎉 No reports yet.\nUsers are behaving well."
                          : "No reports under “${_statusFilter.toUpperCase()}”.\nTry switching the status filter.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final r = reports[i];
                  return _reportCard(r);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Card UI for each report
  Widget _reportCard(ReportModel r) {
    final createdAtLabel = DateFormat('dd MMM yyyy, hh:mm a').format(r.createdAt);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openReportDetail(r),
      splashColor: purple.withValues(alpha:0.08),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: purple.withValues(alpha:0.12),
              child: const Icon(Icons.report_gmailerrorred, color: purple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.reportType,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Against: ${r.reportedUsername}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "By: ${r.reporterName}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    createdAtLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _statusChip(r.status),
                const SizedBox(height: 8),
                const Icon(Icons.chevron_right, size: 20, color: Colors.black45),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Small pill showing status
  Widget _statusChip(String status) {
    String label = status.toUpperCase();
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case 'pending':
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
        icon = Icons.hourglass_top;
        break;
      case 'rejected':
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        icon = Icons.close;
        break;
      case 'banned':
        bg = Colors.red.shade200;
        fg = Colors.red.shade900;
        icon = Icons.block;
        break;
      default: // for "all" or any other status
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // inside _AdminDashboardState in admin_dashboard.dart

  Future<void> _openReportDetail(ReportModel r) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.report, color: purple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.reportType.isEmpty ? "Report detail" : r.reportType,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Reported person: ${r.reportedUsername}"),
                Text("Reporter: ${r.reporterName}"),
                const SizedBox(height: 12),
                const Text(
                  "Description",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(r.description),
                const SizedBox(height: 16),

                if (r.evidenceUrl != null && r.evidenceUrl!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Evidence attached",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "(For now only URL/flag is stored. You can show the image later.)",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),

                const Divider(),
                const SizedBox(height: 12),

                // =======================
                // ACTION BUTTONS
                // =======================
                if (r.status == 'banned') ...[
                  // When the report is already banned:
                  // 1) Unban user & reject report
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await _reportRepo.unbanUserAndRejectReport(
                              reportId: r.id,
                              reportedUserUid: r.reportedUserUid,
                              adminNote:
                                  'Ban reverted – report considered fake / invalid',
                            );

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "User unbanned and report marked as REJECTED.",
                                ),
                              ),
                            );
                          },
                          child: const Text("Unban user & reject report"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Use this if you later find the report was fake or incorrect.",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ] else ...[
                  // Normal flow: Pending / Rejected etc.
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: r.status == 'rejected'
                              ? null
                              : () async {
                                  await _reportRepo.updateReportStatus(
                                    reportId: r.id,
                                    status: 'rejected',
                                    adminNote: 'No action taken',
                                  );
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Report marked as 'Do not take action'.",
                                      ),
                                    ),
                                  );
                                },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: r.status == 'rejected'
                                  ? Colors.grey
                                  : Colors.grey.shade600,
                            ),
                          ),
                          child: const Text("Do not take action"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: r.status == 'banned'
                              ? null
                              : () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Ban user"),
                                      content: Text(
                                        "Ban ${r.reportedUsername.isEmpty ? 'this user' : r.reportedUsername} from ShareEat?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text("Ban"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm != true) return;

                                  await _reportRepo.banUserAndMarkReport(
                                    reportId: r.id,
                                    reportedUserUid: r.reportedUserUid,
                                    adminNote: 'User banned by admin',
                                  );

                                  Navigator.pop(context);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Colors.red,
                                      content: Text(
                                        "User banned and report updated.",
                                      ),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Ban user & close report"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Banned users will not be able to access ShareEat.",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],

                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
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

        final notAvailableOrExpired = math.max(0, totalFoods - availableFoods);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Food Analytics",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

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

            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 700;

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

            _foodsTrendCard(trend),
/*
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
            ...topTypes.map(
              (e) => Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  title: Text(e['type'].toString()),
                  trailing: Text(
                    e['total'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),*/

            const SizedBox(height: 24),

            const Text(
              "Expiring Soon (≤ 3 days)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (expiringSoon.isEmpty) const Text("No foods expiring soon 🎉"),
            ...expiringSoon.map(
              (e) => Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  title: Text(e['title'].toString()),
                  subtitle: Text("Qty: ${e['quantityAvailable']}"),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // TREND CARD / CHART / KPI / DONUT
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

    final barsCount = data.length;
    final aspect = (barsCount <= 7)
        ? 2.2
        : (barsCount <= 14)
            ? 2.6
            : 3.2;

    const xLabelSpace = 18.0;
    const captionSpace = 18.0;
    const topValueSpace = 16.0;

    return AspectRatio(
      aspectRatio: aspect,
      child: LayoutBuilder(
        builder: (context, c) {
          final barsAreaHeight =
              (c.maxHeight - xLabelSpace - captionSpace - topValueSpace)
                  .clamp(40.0, double.infinity);

          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(data.length, (i) {
                      final total = (data[i]['total'] as int?) ?? 0;
                      final ratio = maxVal == 0 ? 0.0 : total / maxVal;
                      final barH =
                          (ratio * barsAreaHeight).clamp(2.0, barsAreaHeight);

                      final showLabel = _trendDays == 7
                          ? true
                          : (i % 5 == 0 || i == data.length - 1);

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
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
                              AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 250),
                                height: barH,
                                decoration: BoxDecoration(
                                  color: purple,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              SizedBox(
                                height: xLabelSpace,
                                child: Center(
                                  child: showLabel
                                      ? Text(
                                          shortLabel(
                                              data[i]['day'].toString()),
                                          style:
                                              const TextStyle(fontSize: 10),
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
              SizedBox(
                height: captionSpace,
                child: Center(
                  child: Text(
                    _trendDays == 7
                        ? "Last 7 days (day of month)"
                        : "Last 30 days (labels every 5 days)",
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54),
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
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            Text(
              title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 140,
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
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
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
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Text(
          "$value",
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }

  // =========================
  // NAV + LOGOUT
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
