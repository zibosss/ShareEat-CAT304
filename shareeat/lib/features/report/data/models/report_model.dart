import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String reportType;
  final String reportedUsername;
  final String reportedUserUid;  // 👈 make sure this exists
  final String description;
  final String? evidenceUrl;

  final String reporterUid;
  final String reporterName;

  final String status; // pending | rejected | banned | ...
  final String? adminNote;

  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.reportType,
    required this.reportedUsername,
    required this.reportedUserUid,
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
      'reportedUserUid': reportedUserUid,   // 👈 save it properly
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

    // 👇 Try both keys so your old reports still load
    final uid = (data['reportedUserUid'] ??
            data['reportedUserId'] ??  // old key
            '') as String;

    return ReportModel(
      id: doc.id,
      reportType: (data['reportType'] ?? '') as String,
      reportedUsername: (data['reportedUsername'] ?? '') as String,
      reportedUserUid: uid,
      description: (data['description'] ?? '') as String,
      evidenceUrl: data['evidenceUrl'] as String?,
      reporterUid: (data['reporterUid'] ?? '') as String,
      reporterName: (data['reporterName'] ?? 'User') as String,
      status: (data['status'] ?? 'pending') as String,
      adminNote: data['adminNote'] as String?,
      createdAt:
          ((data['createdAt'] as Timestamp?)?.toDate()) ?? DateTime.now(),
    );
  }
}
