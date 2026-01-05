// lib/features/report/presentation/report_issue_screen.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:shareeat/features/user_registration/data/user_model.dart';
import 'package:shareeat/features/user_registration/data/user_repository.dart';

class ReportIssueScreen extends StatefulWidget {
  final String bookingId;
  final String foodTitle;
  final String reporterId;
  final String reportedUserId;

  const ReportIssueScreen({
    super.key,
    required this.bookingId,
    required this.foodTitle,
    required this.reporterId,
    required this.reportedUserId,
  });

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  /// Report type options
  final List<String> _reportTypes = const [
    'Did not receive food',
    'Food Quality Issue',
    'Behavior Problem',
    'Wrong Info',
    'Other',
  ];

  String _selectedType = 'Did not receive food';

  final TextEditingController _descriptionController =
      TextEditingController();

  bool _isSubmitting = false;

  // evidence image
  Uint8List? _evidenceBytes;
  String? _evidenceName;

  // reported user (donor)
  final UserRepository _userRepo = UserRepository();
  AppUser? _reportedUser;
  bool _isLoadingReportedUser = true;

  @override
  void initState() {
    super.initState();
    _loadReportedUser();
  }

  Future<void> _loadReportedUser() async {
    try {
      final user = await _userRepo.getUserById(widget.reportedUserId);
      if (!mounted) return;
      setState(() {
        _reportedUser = user;
        _isLoadingReportedUser = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingReportedUser = false;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickEvidence() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _evidenceBytes = bytes;
      _evidenceName = picked.name;
    });
  }

  Future<void> _submitReport() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe what happened.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authUser = FirebaseAuth.instance.currentUser;

      final reporterEmail = authUser?.email ?? '';
      final reporterUid = widget.reporterId;
      // ignore: unused_local_variable
      final reporterName = reporterEmail; // or use stored full name if you have it
      // ignore: unused_local_variable
      final reportedUsername = _reportedUser?.fullName ?? '';

      final reportsRef =
          FirebaseFirestore.instance.collection('reports');

      await reportsRef.add({
        'bookingId': widget.bookingId,
        'foodTitle': widget.foodTitle,
        'reportType': _selectedType,                     // rename 'type' → 'reportType'
        'description': _descriptionController.text.trim(),
        'reporterUid': reporterUid,
        'reporterName': reporterEmail,                   // or a nicer name if you have it
        'reportedUserUid': widget.reportedUserId,        // 👈 important
        'reportedUsername': _reportedUser?.fullName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'hasEvidence': _evidenceBytes != null,
      });



      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reporterEmail =
        FirebaseAuth.instance.currentUser?.email ?? '';
    const purple = Color(0xFF7A2B93);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: purple,
        title: const Text(
          'Report an Issue',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header line under app bar – centred RichText
          Container(
            width: double.infinity,
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Center(
              child: _SafetyHeaderText(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // food title
                  Text(
                    widget.foodTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Report type label
                  const Text(
                    'Report Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ==== Figma-style symmetric buttons ====
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double totalWidth = constraints.maxWidth;
                      final double gap = 12;
                      final double itemWidth =
                          (totalWidth - gap) / 2; // 2 per row

                      return Column(
                        children: [
                          // first row: [0] [1]
                          Row(
                            children: [
                              _buildReportTypeButton(
                                label: _reportTypes[0],
                                width: itemWidth,
                              ),
                              SizedBox(width: gap),
                              _buildReportTypeButton(
                                label: _reportTypes[1],
                                width: itemWidth,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // second row: [2] [3]
                          Row(
                            children: [
                              _buildReportTypeButton(
                                label: _reportTypes[2],
                                width: itemWidth,
                              ),
                              SizedBox(width: gap),
                              _buildReportTypeButton(
                                label: _reportTypes[3],
                                width: itemWidth,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // third row: "Other" centred (full width)
                          Align(
                            alignment: Alignment.center,
                            child: _buildReportTypeButton(
                              label: _reportTypes[4],
                              width: totalWidth * 0.6,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Username (reporter)
                  const Text(
                    'Username',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: reporterEmail,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Who is being reported (donor)
                  const Text(
                    'Reported person (donor)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _isLoadingReportedUser
                          ? 'Loading donor info...'
                          : (_reportedUser?.fullName.isNotEmpty == true
                              ? _reportedUser!.fullName
                              : 'Unknown user'),
                      style: TextStyle(
                        color: _isLoadingReportedUser
                            ? Colors.grey
                            : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Describe what happened',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Describe what happened...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Upload evidence
                  Center(
                    child: GestureDetector(
                      onTap: _pickEvidence,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade400,
                            style: BorderStyle.solid,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _evidenceName == null
                                  ? 'Upload evidence'
                                  : _evidenceName!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                              ),
                            )
                          : const Text(
                              'SUBMIT',
                              style: TextStyle(
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Single Figma-style button for report type
  Widget _buildReportTypeButton({
    required String label,
    required double width,
  }) {
    const purple = Color(0xFF7A2B93);
    final bool selected = _selectedType == label;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedType = label);
      },
      child: Container(
        width: width,
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? purple : Colors.grey[200],
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered “Help us keep SharEat safe…” text with purple highlight
class _SafetyHeaderText extends StatelessWidget {
  const _SafetyHeaderText();

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        style: TextStyle(
          fontSize: 13,
          color: Colors.black87,
        ),
        children: [
          TextSpan(text: 'Help us keep '),
          TextSpan(
            text: 'SharEat safe',
            style: TextStyle(
              color: Color(0xFF7A2B93),
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: ' for everyone.'),
        ],
      ),
    );
  }
}
