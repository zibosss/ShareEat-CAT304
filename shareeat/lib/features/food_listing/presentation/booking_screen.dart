import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// ✅ IMPORTS (Adjust these to match your folder structure if needed)
import 'package:shareeat/features/food_listing/data/booking_repository.dart';
import 'package:shareeat/features/food_listing/data/data/models/booking_model.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text("My Bookings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF7A2B93),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF7A2B93),
            tabs: [
              Tab(text: "My Requests"),
              Tab(text: "My Donations"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MyRequestsTab(),
            _MyDonationsTab(), // This is the section we fixed
          ],
        ),
      ),
    );
  }
}

/* =========================================================
   TAB 1: MY REQUESTS (For users requesting food)
   ========================================================= */
class _MyRequestsTab extends StatelessWidget {
  const _MyRequestsTab();

  void _showQRCode(BuildContext context, String qrData) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Verification Code",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: qrData.isNotEmpty 
                  ? QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 220.0,
                      backgroundColor: Colors.white,
                    )
                  : const Column(
                      children: [
                        Icon(Icons.error_outline, size: 50, color: Colors.orange),
                        SizedBox(height: 10),
                        Text("QR Data Missing"),
                      ],
                    ),
              ),
              const SizedBox(height: 20),
              const Text("Show this to the donor", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A2B93),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Close", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const Center(child: Text("Please log in"));

    return StreamBuilder<List<BookingModel>>(
      stream: BookingRepository().watchMyBookings(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fastfood_outlined, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text("No requests yet", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final dateStr = DateFormat('dd MMM, hh:mm a').format(booking.createdAt);
            final bool hasQr = booking.qrCodeData.isNotEmpty;

            Color statusColor;
            switch (booking.status.toLowerCase()) {
              case 'completed': statusColor = Colors.blue; break;
              case 'rejected': statusColor = Colors.red; break;
              default: statusColor = Colors.orange;
            }

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            booking.foodTitle,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            booking.status.toUpperCase(),
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("Requested: $dateStr", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(height: 16),
                    const Divider(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: hasQr ? () => _showQRCode(context, booking.qrCodeData) : null,
                        icon: const Icon(Icons.qr_code, size: 18),
                        label: Text(hasQr ? "View QR" : "No QR"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7A2B93),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                      ),
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
   TAB 2: MY DONATIONS (For donors to verify pickup)
   ========================================================= */
class _MyDonationsTab extends StatelessWidget {
  const _MyDonationsTab();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const Center(child: Text("Please log in"));

    return StreamBuilder<List<BookingModel>>(
      // ✅ This calls the repository to find requests WHERE ownerId == You
      stream: BookingRepository().watchMyDonations(userId),
      builder: (context, snapshot) {
        
        // 1. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Error State (This fixes the "infinite spinner" problem)
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 50, color: Colors.red),
                  const SizedBox(height: 10),
                  const Text("Database Error", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(
                    "${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  const Text("(Check your debug console for a link to fix this)", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        final donations = snapshot.data ?? [];

        // 3. Empty State
        if (donations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.volunteer_activism, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text("No incoming requests yet", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // 4. List of Requests
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final booking = donations[index];
            final bool isCompleted = booking.status == 'completed';

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            booking.foodTitle,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.blue[50] : Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isCompleted ? Colors.blue : Colors.orange),
                          ),
                          child: Text(
                            booking.status.toUpperCase(),
                            style: TextStyle(
                              color: isCompleted ? Colors.blue : Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.qr_code_scanner),
                        label: Text(isCompleted ? "Pickup Completed" : "Scan to Verify"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCompleted ? Colors.grey : const Color(0xFF7A2B93),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isCompleted
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _ScanQrScreen(booking: booking),
                                  ),
                                );
                              },
                      ),
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
   SCANNER SCREEN (To Verify QR)
   ========================================================= */
class _ScanQrScreen extends StatefulWidget {
  final BookingModel booking;
  const _ScanQrScreen({required this.booking});

  @override
  State<_ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<_ScanQrScreen> {
  bool _isVerified = false; 

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

          // Compare Code
          if (scannedCode == widget.booking.qrCodeData) {
            setState(() { _isVerified = true; });

            // Mark as completed
            await BookingRepository().markBookingCompleted(widget.booking.id);

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Verified! Hand over the food."),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.pop(context);
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Wrong QR Code!"),
                backgroundColor: Colors.red,
                duration: Duration(milliseconds: 500),
              ),
            );
          }
        },
      ),
    );
  }
}