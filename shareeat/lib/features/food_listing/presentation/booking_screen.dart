// lib/features/food_listing/presentation/booking_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:shareeat/features/food_listing/data/booking_repository.dart';
// adjust this path if your BookingModel is elsewhere:
import 'package:shareeat/features/food_listing/data/data/models/booking_model.dart';
import 'package:shareeat/features/report/presentation/report_issue_screen.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            "My Bookings",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
          ),
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
            _MyDonationsTab(),
          ],
        ),
      ),
    );
  }
}

/* =========================================================
   TAB 1: MY REQUESTS (recipient)
   ========================================================= */
class _MyRequestsTab extends StatelessWidget {
  const _MyRequestsTab();

  void _showBookingOptions(BuildContext context, BookingModel booking) {
    final isPending = booking.status.toLowerCase() == 'pending';
    final isCompleted = booking.status.toLowerCase() == 'completed';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          booking.foodTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Requested Quantity: ${booking.quantity}"),
            const SizedBox(height: 10),
            Text(
              "Status: ${booking.status.toUpperCase()}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (isPending)
              const Text(
                "Do you want to cancel this request? "
                "This will remove the item and restore the stock.",
              )
            else if (isCompleted)
              const Text(
                "This pickup is completed.\n"
                "If something went wrong (did not receive food, food issue, behaviour, etc.), "
                "you can submit a report.",
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
          if (isPending)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_forever, size: 18),
              label: const Text("Cancel Request"),
              onPressed: () async {
                try {
                  Navigator.pop(ctx);
                  await BookingRepository().cancelBooking(booking);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Request cancelled & stock restored.",
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                }
              },
            ),
          if (isCompleted)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // close dialog

                final currentUserId =
                    FirebaseAuth.instance.currentUser?.uid ?? '';

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReportIssueScreen(
                      bookingId: booking.id,
                      foodTitle: booking.foodTitle,
                      reporterId: currentUserId, // requester
                      reportedUserId: booking.ownerId, // donor
                    ),
                  ),
                );
              },
              child: const Text(
                "Report",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  void _showQRCode(BuildContext context, String qrData) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: qrData.isNotEmpty
                    ? QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 220.0,
                        backgroundColor: Colors.white,
                      )
                    : const Icon(Icons.error, size: 50),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
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
    if (userId == null) {
      return const Center(child: Text("Please log in"));
    }

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
          return const Center(child: Text("No requests yet"));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final dateStr =
                DateFormat('dd MMM, hh:mm a').format(booking.createdAt);

            Color statusColor;
            switch (booking.status.toLowerCase()) {
              case 'completed':
                statusColor = Colors.blue;
                break;
              case 'rejected':
                statusColor = Colors.red;
                break;
              default:
                statusColor = Colors.orange;
            }

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => _showBookingOptions(context, booking),
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
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusColor.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              booking.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Requested: ${booking.quantity} items  •  $dateStr",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: booking.qrCodeData.isNotEmpty
                              ? () => _showQRCode(context, booking.qrCodeData)
                              : null,
                          icon: const Icon(Icons.qr_code, size: 18),
                          label: const Text("View QR"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7A2B93),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
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
   TAB 2: MY DONATIONS (donor)
   ========================================================= */
class _MyDonationsTab extends StatelessWidget {
  const _MyDonationsTab();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const Center(child: Text("Please log in"));

    return StreamBuilder<List<BookingModel>>(
      stream: BookingRepository().watchMyDonations(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final donations = snapshot.data ?? [];
        if (donations.isEmpty) {
          return const Center(child: Text("No incoming requests"));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: donations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final booking = donations[index];
            final bool isCompleted =
                booking.status.toLowerCase() == 'completed';

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            booking.foodTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.blue[50]
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            booking.status.toUpperCase(),
                            style: TextStyle(
                              color: isCompleted
                                  ? Colors.blue
                                  : Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("Request for: ${booking.quantity} items"),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.qr_code_scanner),
                        label: Text(
                          isCompleted
                              ? "Pickup Completed"
                              : "Scan to Verify",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCompleted
                              ? Colors.grey
                              : const Color(0xFF7A2B93),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: isCompleted
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
   QR SCANNER (donor)
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
          if (barcode.rawValue == null) return;

          if (barcode.rawValue == widget.booking.qrCodeData) {
            setState(() => _isVerified = true);
            await BookingRepository()
                .markBookingCompleted(widget.booking.id);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Verified!"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Wrong QR!"),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
}
