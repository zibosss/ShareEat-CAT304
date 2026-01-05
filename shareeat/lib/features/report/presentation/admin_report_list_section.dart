import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/report_model.dart';
import '../data/report_repository.dart';

class AdminReportListSection extends StatefulWidget {
  const AdminReportListSection({super.key});

  @override
  State<AdminReportListSection> createState() =>
      _AdminReportListSectionState();
}

class _AdminReportListSectionState extends State<AdminReportListSection> {
  final ReportRepository _repo = ReportRepository();

  // 'pending', 'ignored', 'banned', 'all'
  String _selectedStatus = 'pending';

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    const purple = Color(0xFF7A2B93);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // status filter row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedStatus,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: 'pending',
                    child: Text('Pending'),
                  ),
                  DropdownMenuItem(
                    value: 'ignored',
                    child: Text('Ignored'),
                  ),
                  DropdownMenuItem(
                    value: 'banned',
                    child: Text('Banned'),
                  ),
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('All'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedStatus = value);
                },
              ),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<List<ReportModel>>(
            stream: _repo.watchReports(status: _selectedStatus),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading reports:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final reports = snapshot.data ?? [];

              if (reports.isEmpty) {
                return const Center(
                  child: Text('No reports for this status.'),
                );
              }

              return ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: reports.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return _ReportListTile(
                    report: report,
                    onIgnore: () async {
                      await _repo.updateReportStatus(
                        reportId: report.id,
                        status: 'ignored',
                        adminNote: 'No action taken',
                      );
                    },
                    onBan: () async {
                      await _repo.banUserAndMarkReport(
                        reportId: report.id,
                        reportedUserUid: report.reportedUserUid,
                        adminNote: 'User banned by admin',
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReportListTile extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onIgnore;
  final VoidCallback onBan;

  const _ReportListTile({
    required this.report,
    required this.onIgnore,
    required this.onBan,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7A2B93);
    final dateStr = DateFormat('dd MMM yyyy, HH:mm')
        .format(report.createdAt);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // simple detail dialog; you can replace with a full screen later
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(report.reportType),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reported user: ${report.reportedUsername}'),
                  const SizedBox(height: 8),
                  Text('Reporter: ${report.reporterName}'),
                  const SizedBox(height: 8),
                  Text('Status: ${report.status}'),
                  const SizedBox(height: 8),
                  Text('Created: $dateStr'),
                  const SizedBox(height: 12),
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(report.description),
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
        },
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // top row: type + status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      report.reportType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: purple.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report.status.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: purple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Reported: ${report.reportedUsername}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                dateStr,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onIgnore,
                      child: const Text('Do not take action'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onBan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Ban user'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
