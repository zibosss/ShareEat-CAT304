import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:shareeat/features/food_listing/data/booking_repository.dart';
import 'package:shareeat/features/food_listing/data/data/models/booking_model.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Bookings"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "My Requests"),
              Tab(text: "My Donations"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MyRequestsTab(),
            _MyDonationsTab(),
          ],
        ),
      ),
    );
  }
}

/* =========================================================
   MY REQUESTS (REQUESTER VIEW)
   ========================================================= */

class _MyRequestsTab extends StatelessWidget {
  const _MyRequestsTab();

  void _showQRCode(BuildContext context, String qrData) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Your QR Code"),
        content: QrImageView(
          data: qrData,
          size: 200,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text("Please log in"));
    }

    return StreamBuilder<List<BookingModel>>(
      stream: BookingRepository().watchMyBookings(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!;
        if (bookings.isEmpty) {
          return const Center(child: Text("No requests yet"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final dateStr =
                DateFormat('dd MMM, hh:mm a').format(booking.createdAt);

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.foodTitle,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Requested: $dateStr",
                      style: TextStyle(color: Colors.grey[600]),
                    ),

                    const Divider(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          label: Text(booking.status.toUpperCase()),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              _showQRCode(context, booking.qrCodeData),
                          child: const Text("View QR"),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/* =========================================================
   MY DONATIONS (DONOR VIEW)
   ========================================================= */

class _MyDonationsTab extends StatelessWidget {
  const _MyDonationsTab();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text("Please log in"));
    }

    return StreamBuilder<List<BookingModel>>(
      stream: BookingRepository().watchMyDonations(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final donations = snapshot.data!;
        if (donations.isEmpty) {
          return const Center(child: Text("No incoming requests"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final booking = donations[index];

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.foodTitle,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text("Status: ${booking.status.toUpperCase()}"),

                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text("Scan QR"),
                      onPressed: booking.status == 'completed'
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      _ScanQrScreen(booking: booking),
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/* =========================================================
   QR SCAN SCREEN – VERIFICATION (FIXED)
   ========================================================= */

class _ScanQrScreen extends StatefulWidget {
  final BookingModel booking;
  const _ScanQrScreen({required this.booking});

  @override
  State<_ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<_ScanQrScreen> {
  bool _isVerified = false; // prevent multiple scans

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR")),
      body: MobileScanner(
        onDetect: (BarcodeCapture capture) async {
          if (_isVerified) return;
          if (capture.barcodes.isEmpty) return;

          final Barcode barcode = capture.barcodes.first;
          final String? scannedCode = barcode.rawValue;

          if (scannedCode == null) return;

          if (scannedCode == widget.booking.qrCodeData) {
            _isVerified = true;

            await BookingRepository()
                .markBookingCompleted(widget.booking.id);

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Pickup verified successfully"),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
