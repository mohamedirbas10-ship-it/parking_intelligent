import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../../models/parking_spot.dart';
import '../../widgets/time_selection_dialog.dart';
import 'qr_code_screen.dart';

class ParkingHomeScreen extends StatefulWidget {
  const ParkingHomeScreen({super.key});

  @override
  State<ParkingHomeScreen> createState() => _ParkingHomeScreenState();
}

class _ParkingHomeScreenState extends State<ParkingHomeScreen> {
  String _userName = '';
  String _userId = '';
  
  // Track booked slots
  Map<String, ParkingSpot> bookedSlots = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
      _userId = prefs.getString('userEmail') ?? 'user@example.com';
    });
  }

  Future<void> _showMyBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('reservationHistory') ?? [];
    
    if (historyJson.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No QR codes yet. Book a parking slot first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Parse history into ParkingSpot objects
    final List<ParkingSpot> spots = historyJson.map((json) {
      final parts = json.split('|');
      return ParkingSpot(
        id: parts[0],
        name: parts[1],
        isAvailable: false,
        reservationTime: DateTime.parse(parts[2]),
        validityHours: int.parse(parts[3]),
        qrCode: parts[4],
        userId: parts.length > 5 ? parts[5] : '',
        userName: parts.length > 6 ? parts[6] : '',
      );
    }).toList();

    // Show bottom sheet with QR code history
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.blue.shade600, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'My QR Codes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${spots.length} Total',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: spots.length,
                  itemBuilder: (context, index) {
                    final spot = spots[spots.length - 1 - index]; // Show newest first
                    return _buildQRHistoryCard(spot);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRHistoryCard(ParkingSpot spot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_parking,
                color: Colors.green.shade600,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Slot ${spot.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${spot.validityHours} hour${spot.validityHours > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(spot.reservationTime ?? DateTime.now()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QRCodeScreen(spot: spot),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'View QR',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    
    return '$day/$month/$year $hour:$minute';
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userEmail');
    await prefs.remove('userName');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Blue Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_parking_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'SMART CAR PARKING',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.qr_code, color: Colors.white),
                  tooltip: 'My QR Codes',
                  onPressed: _showMyBookings,
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Logout',
                  onPressed: _logout,
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Parking Slots',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Entry Label
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'ENTRY',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Parking Slots Grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Left Column
                          Expanded(
                            child: Column(
                              children: [
                                _buildParkingSlot('A1', false),
                                const SizedBox(height: 40),
                                _buildParkingSlot('A3', true),
                                const SizedBox(height: 40),
                                _buildParkingSlot('A5', true),
                              ],
                            ),
                          ),
                          
                          // Center Road
                          SizedBox(
                            width: 60,
                            child: Column(
                              children: [
                                Container(
                                  height: 400,
                                  width: 3,
                                  color: Colors.grey.shade300,
                                ),
                              ],
                            ),
                          ),
                          
                          // Right Column
                          Expanded(
                            child: Column(
                              children: [
                                _buildParkingSlot('A2', true),
                                const SizedBox(height: 40),
                                _buildParkingSlot('A4', true),
                                const SizedBox(height: 40),
                                _buildParkingSlot('A6', true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParkingSlot(String slotId, bool isAvailable) {
    // Check if this slot is booked by the user
    final isBooked = bookedSlots.containsKey(slotId);
    final actuallyAvailable = isAvailable && !isBooked;
    
    return Column(
      children: [
        // Parking Slot (removed top number)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: actuallyAvailable ? Colors.grey.shade300 : (isBooked ? Colors.green.shade200 : Colors.red.shade200),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Car Icon or Empty with parking lines
              if (!actuallyAvailable)
                Icon(
                  Icons.directions_car,
                  size: 40,
                  color: isBooked ? Colors.green.shade700 : Colors.grey.shade700,
                )
              else
                Container(
                  height: 40,
                  child: CustomPaint(
                    size: const Size(double.infinity, 40),
                    painter: ParkingLinesPainter(),
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Slot ID
              Text(
                slotId,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Book Button or Status
              if (actuallyAvailable)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showBookingDialog(slotId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'BOOK',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                )
              else if (isBooked)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Show QR code for booked slot
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QRCodeScreen(spot: bookedSlots[slotId]!),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'VIEW QR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'OCCUPIED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showBookingDialog(String slotId) async {
    // Show time selection dialog
    final selectedHours = await showDialog<int>(
      context: context,
      builder: (context) => TimeSelectionDialog(spotName: slotId),
    );

    if (selectedHours != null) {
      final now = DateTime.now();
      final spot = ParkingSpot(
        id: slotId,
        name: slotId,
        isAvailable: false,
        reservationTime: now,
        validityHours: selectedHours,
        qrCode: 'QR_${slotId}_${now.millisecondsSinceEpoch}',
        userId: _userId,
        userName: _userName,
      );

      setState(() {
        bookedSlots[slotId] = spot;
      });

      // Save to history
      await _saveReservationHistory(spot);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Slot $slotId booked for $selectedHours hour${selectedHours > 1 ? 's' : ''}!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to QR code screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QRCodeScreen(spot: spot),
          ),
        );
      }
    }
  }

  Future<void> _saveReservationHistory(ParkingSpot spot) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('reservationHistory') ?? [];
    
    final spotJson = '${spot.id}|${spot.name}|${spot.reservationTime!.toIso8601String()}|${spot.validityHours}|${spot.qrCode}|${spot.userId}|${spot.userName}';
    historyJson.add(spotJson);
    
    await prefs.setStringList('reservationHistory', historyJson);
  }
}

// Custom painter for parking lines in empty slots
class ParkingLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dashedPaint = Paint()
      ..color = Colors.blue.shade200
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw parking bay outline
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.2, 5, size.width * 0.6, size.height - 10),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, paint);

    // Draw center dashed line
    final dashWidth = 4.0;
    final dashSpace = 3.0;
    double startY = 10;
    
    while (startY < size.height - 10) {
      canvas.drawLine(
        Offset(size.width * 0.5, startY),
        Offset(size.width * 0.5, startY + dashWidth),
        dashedPaint,
      );
      startY += dashWidth + dashSpace;
    }

    // Draw "P" icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'P',
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}