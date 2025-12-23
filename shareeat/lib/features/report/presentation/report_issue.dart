import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/models/report_model.dart';
import '../data/report_repository.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _repo = ReportRepository();

  final _usernameController = TextEditingController();
  final _descController = TextEditingController();

  final List<String> _types = const [
    'Fake booking',
    'Food Quality Issue',
    'Behavior Problem',
    'Wrong Info',
    'Other',
  ];

  String? _selectedType;
  File? _evidence;
  bool _submitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickEvidence() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x == null) return;
    setState(() => _evidence = File(x.path));
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must login first.')),
      );
      return;
    }

    final type = _selectedType;
    final reportedUsername = _usernameController.text.trim();
    final desc = _descController.text.trim();

    if (type == null || reportedUsername.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      String? url;
      if (_evidence != null) {
        url = await _repo.uploadEvidence(file: _evidence!, reporterUid: user.uid);
      }

      final report = ReportModel(
        id: '',
        reportType: type,
        reportedUsername: reportedUsername,
        description: desc,
        evidenceUrl: url,
        reporterUid: user.uid,
        reporterName: user.displayName ?? 'User',
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _repo.submitReport(report);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7A2B93);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: purple,
        title: const Text('Report an Issue'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Help us keep'),
            const SizedBox(height: 2),
            RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(text: 'SharEat ', style: TextStyle(fontWeight: FontWeight.bold, color: purple)),
                  TextSpan(text: 'safe for everyone.'),
                ],
              ),
            ),
            const SizedBox(height: 18),

            const Text('Report Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: _types.map((t) {
                final selected = _selectedType == t;
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 18 * 2 - 14) / 2,
                  child: InkWell(
                    onTap: () => setState(() => _selectedType = t),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                      decoration: BoxDecoration(
                        color: selected ? purple.withOpacity(0.12) : const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selected ? purple : Colors.transparent),
                      ),
                      child: Center(
                        child: Text(
                          t,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected ? purple : Colors.black54,
                            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Describe what happened',
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
            ),

            const SizedBox(height: 18),

            Center(
              child: InkWell(
                onTap: _pickEvidence,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: _evidence == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 32),
                            SizedBox(height: 8),
                            Text('Upload\nevidence', textAlign: TextAlign.center),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_evidence!, fit: BoxFit.cover),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('SUBMIT', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
