import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String reportType;
  final String reportedUsername;
  final String description;
  final String? evidenceUrl;

  final String reporterUid;
  final String reporterName;

  final String status; // pending | under_review | resolved | rejected
  final String? adminNote;

  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.reportType,
    required this.reportedUsername,
    required this.description,
    required this.reporterUid,
    required this.reporterName,
    required this.status,
    required this.createdAt,
    this.evidenceUrl,
    this.adminNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'reportType': reportType,
      'reportedUsername': reportedUsername,
      'description': description,
      'evidenceUrl': evidenceUrl,
      'reporterUid': reporterUid,
      'reporterName': reporterName,
      'status': status,
      'adminNote': adminNote,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static ReportModel fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      reportType: (data['reportType'] ?? '') as String,
      reportedUsername: (data['reportedUsername'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      evidenceUrl: data['evidenceUrl'] as String?,
      reporterUid: (data['reporterUid'] ?? '') as String,
      reporterName: (data['reporterName'] ?? 'User') as String,
      status: (data['status'] ?? 'pending') as String,
      adminNote: data['adminNote'] as String?,
      createdAt: ((data['createdAt'] as Timestamp?)?.toDate()) ?? DateTime.now(),
    );
  }
}
