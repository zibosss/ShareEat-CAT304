import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'models/report_model.dart';


class ReportRepository {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  CollectionReference get _reports => _db.collection('reports');

  Future<String?> uploadEvidence({
    required File file,
    required String reporterUid,
  }) async {
    final fileName = 'evidence_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('reports/$reporterUid/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> submitReport(ReportModel report) async {
    await _reports.add(report.toMap());
  }

  Stream<List<ReportModel>> streamReports({String? status}) {
    Query q = _reports.orderBy('createdAt', descending: true);
    if (status != null && status.isNotEmpty) {
      q = q.where('status', isEqualTo: status);
    }
    return q.snapshots().map(
          (snap) => snap.docs.map(ReportModel.fromDoc).toList(),
        );
  }

  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    String? adminNote,
  }) async {
    await _reports.doc(reportId).update({
      'status': status,
      'adminNote': adminNote,
    });
  }

  /// Simple counts for your analytics tab
  Future<Map<String, int>> getAdminCounts() async {
    final reportsSnap = await _reports.get();
    final pendingSnap = await _reports.where('status', isEqualTo: 'pending').get();

    // Optional: only if these collections exist
    final foodsSnap = await _db.collection('foods').get().catchError((_) => null);
    final bookingsSnap = await _db.collection('bookings').get().catchError((_) => null);

    return {
      'reportsTotal': reportsSnap.size,
      'reportsPending': pendingSnap.size,
      'foodsTotal': foodsSnap.size,
      'bookingsTotal': bookingsSnap.size,
    };
  }
}
