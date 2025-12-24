// lib/features/report/data/report_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/report_model.dart';

class ReportRepository {
  final CollectionReference _reportsRef =
      FirebaseFirestore.instance.collection('reports');

  /// Stream reports for admin, filtered by status.
  /// status = 'all' will return all reports.
  Stream<List<ReportModel>> watchReports({String status = 'pending'}) {
    Query query =
        _reportsRef.orderBy('createdAt', descending: true);

    if (status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => ReportModel.fromDoc(doc)).toList(),
    );
  }

  /// Mark a report as ignored / resolved / etc.
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    String? adminNote,
  }) async {
    await _reportsRef.doc(reportId).update({
      'status': status,
      'adminNote': adminNote,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔒 Recalculate isBanned on user document:
  ///   isBanned = true  if ANY report for this user has status == "banned"
  ///   isBanned = false otherwise
  Future<void> _refreshUserBanFlag(String reportedUserUid) async {
    if (reportedUserUid.isEmpty) return;

    final bannedSnapshot = await _reportsRef
        .where('reportedUserUid', isEqualTo: reportedUserUid)
        .where('status', isEqualTo: 'banned')
        .limit(1)
        .get();

    final bool stillBanned = bannedSnapshot.docs.isNotEmpty;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(reportedUserUid);

    await userRef.update({
      'isBanned': stillBanned,
    });
  }

  /// Ban a user and mark the report as "banned".
  Future<void> banUserAndMarkReport({
    required String reportId,
    required String reportedUserUid,
    String? adminNote,
  }) async {
    // 1) Update this report’s status -> banned
    await _reportsRef.doc(reportId).update({
      'status': 'banned',
      'adminNote': adminNote,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2) Recalculate global isBanned flag for that user
    await _refreshUserBanFlag(reportedUserUid);
  }

  /// Unban user for THIS report -> report becomes REJECTED
  /// and isBanned will be recalculated based on remaining bans.
  Future<void> unbanUserAndRejectReport({
    required String reportId,
    required String reportedUserUid,
    String? adminNote,
  }) async {
    // 1) This report is now rejected (fake/invalid)
    await _reportsRef.doc(reportId).update({
      'status': 'rejected',
      'adminNote': adminNote ?? 'Ban reverted – report considered fake/invalid',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2) Recalculate global isBanned flag based on other reports
    await _refreshUserBanFlag(reportedUserUid);
  }
}
