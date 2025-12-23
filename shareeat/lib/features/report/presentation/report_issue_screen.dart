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
  final List<String> _reportTypes = const [
    'Did not receive food',
    'Food Quality Issue',
    'Behavior Problem',
    'Wrong Info',
    'Other',
  ];

  String _selectedType = 'Did not receive food';

  final TextEditingController _descriptionController = TextEditingController();

  bool _isSubmitting = false;

  Uint8List? _evidenceBytes;
  String? _evidenceName;

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
      setState(() => _isLoadingReportedUser = false);
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

      await FirebaseFirestore.instance.collection('reports').add({
        'bookingId': widget.bookingId,
        'foodTitle': widget.foodTitle,
        'type': _selectedType,
        'description': _descriptionController.text.trim(),
        'reporterId': widget.reporterId,
        'reporterEmail': authUser?.email ?? '',
        'reportedUserId': widget.reportedUserId,
        'reportedUserName': _reportedUser?.fullName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'open',
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reporterEmail =
        FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF7A2B93),
        title: const Text(
          'Report an Issue',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 🔹 HEADER (CENTERED)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  'Help us keep ShareEat safe for everyone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.foodTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Report Type',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _reportTypes.map((type) {
                      final selected = _selectedType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _selectedType = type);
                        },
                        selectedColor: const Color(0xFF7A2B93),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                        ),
                        backgroundColor: Colors.grey[200],
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 🔹 USERNAME
                  const Text(
                    'Username',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(text: reporterEmail),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: UnderlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔹 REPORTED PERSON
                  const Text(
                    'Reported person (donor)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _isLoadingReportedUser
                          ? 'Loading...'
                          : (_reportedUser?.fullName.isNotEmpty == true
                              ? _reportedUser!.fullName
                              : 'Unknown user'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Describe what happened',
                    style: TextStyle(fontWeight: FontWeight.w600),
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

                  Center(
                    child: GestureDetector(
                      onTap: _pickEvidence,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_outlined, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              _evidenceName ?? 'Upload evidence',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7A2B93),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
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
}
