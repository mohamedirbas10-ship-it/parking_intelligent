import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/parking_spot.dart';
import '../auth/login_screen.dart';
import 'qr_code_screen.dart';
import 'history_screen.dart';
import '../../widgets/time_selection_dialog.dart';
import '../../widgets/animated_car_logo.dart';
import '../../widgets/parked_car_widget.dart';

class ParkingHomeScreen extends StatefulWidget {
  const ParkingHomeScreen({super.key});

  @override
  State<ParkingHomeScreen> createState() => _ParkingHomeScreenState();
}

class _ParkingHomeScreenState extends State<ParkingHomeScreen> {
  List<ParkingSpot> _parkingSpots = [];
  String _userName = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeParkingSpots();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
      _userId = prefs.getString('userEmail') ?? 'user@example.com';
    });
  }

  void _initializeParkingSpots() {
    _parkingSpots = [
      ParkingSpot(
        id: 'A1',
        name: 'A1',
        isAvailable: true,
        validityHours: 1,
      ),
      ParkingSpot(
        id: 'A2',
        name: 'A2',
        isAvailable: true,
        validityHours: 1,
      ),
      ParkingSpot(
        id: 'A3',
        name: 'A3',
        isAvailable: false,
        validityHours: 1,
        reservationTime: DateTime.now().subtract(const Duration(minutes: 30)),
        qrCode: 'QR_A3_${DateTime.now().millisecondsSinceEpoch}',
      ),
      ParkingSpot(
        id: 'A4',
        name: 'A4',
        isAvailable: true,
        validityHours: 1,
      ),
      ParkingSpot(
        id: 'A5',
        name: 'A5',
        isAvailable: false,
        validityHours: 1,
        reservationTime: DateTime.now().subtract(const Duration(minutes: 45)),
        qrCode: 'QR_A5_${DateTime.now().millisecondsSinceEpoch}',
      ),
    ];
  }

  Future<void> _reserveSpot(ParkingSpot spot) async {
    if (spot.isAvailable) {
      // Show time selection dialog
      final selectedHours = await showDialog<int>(
        context: context,
        builder: (context) => TimeSelectionDialog(spotName: spot.name),
      );

      if (selectedHours != null) {
        final now = DateTime.now();
        final newSpot = spot.copyWith(
          isAvailable: false,
          reservationTime: now,
          validityHours: selectedHours,
          qrCode: 'QR_${spot.id}_${now.millisecondsSinceEpoch}',
          userId: _userId,
          userName: _userName,
        );

        setState(() {
          _parkingSpots = _parkingSpots.map((s) {
            if (s.id == spot.id) {
              return newSpot;
            }
            return s;
          }).toList();
        });

        // Save to history
        await _saveReservationHistory(newSpot);

        // Navigate to QR code screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QRCodeScreen(spot: newSpot),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final crossAxisCount = isMobile ? 2 : 3;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Welcome, $_userName',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade700,
        elevation: 0,
        shadowColor: Colors.transparent,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.history, color: Colors.blue.shade600),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.logout, color: Colors.red.shade600),
              onPressed: _logout,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const AnimatedCarLogo(
                        size: 32,
                        carColor: Colors.white,
                        isAnimated: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Smart Parking',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Find and reserve your spot',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Parking Spots',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      '${_parkingSpots.where((spot) => spot.isAvailable).length} Available',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: isMobile ? 1.1 : 1.3,
                    crossAxisSpacing: isMobile ? 12 : 16,
                    mainAxisSpacing: isMobile ? 12 : 16,
                  ),
                  itemCount: _parkingSpots.length,
                  itemBuilder: (context, index) {
                    final spot = _parkingSpots[index];
                    return _buildParkingSpotCard(spot, isMobile);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParkingSpotCard(ParkingSpot spot, bool isMobile) {
    final isExpired = spot.isExpired;
    final timeRemaining = spot.timeRemaining;
    
    Color cardColor;
    Color borderColor;
    Color iconColor;
    String statusText;
    Color statusColor;
    
    if (spot.isAvailable) {
      cardColor = Colors.green.shade50;
      borderColor = Colors.green.shade300;
      iconColor = Colors.green.shade600;
      statusText = 'Available';
      statusColor = Colors.green.shade700;
    } else if (isExpired) {
      cardColor = Colors.red.shade50;
      borderColor = Colors.red.shade300;
      iconColor = Colors.red.shade600;
      statusText = 'Expired';
      statusColor = Colors.red.shade700;
    } else {
      cardColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade300;
      iconColor = Colors.orange.shade600;
      statusText = 'Reserved';
      statusColor = Colors.orange.shade700;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: spot.isAvailable
                      ? Icon(
                          Icons.local_parking,
                          size: isMobile ? 28 : 32,
                          color: iconColor,
                        )
                      : ParkedCarWidget(
                          size: isMobile ? 28 : 32,
                          carColor: iconColor,
                          isAnimated: true,
                        ),
                ),
                SizedBox(height: isMobile ? 8 : 12),
                Text(
                  'Spot ${spot.name}',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!spot.isAvailable && !isExpired) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      timeRemaining,
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 11,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                if (!spot.isAvailable) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Duration: ${spot.validityHours}h',
                    style: TextStyle(
                      fontSize: isMobile ? 9 : 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: isMobile ? 36 : 40,
              child: ElevatedButton(
                onPressed: spot.isAvailable ? () => _reserveSpot(spot) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: spot.isAvailable 
                      ? Colors.blue.shade600 
                      : Colors.grey.shade300,
                  foregroundColor: spot.isAvailable 
                      ? Colors.white 
                      : Colors.grey.shade600,
                  elevation: spot.isAvailable ? 2 : 0,
                  shadowColor: spot.isAvailable 
                      ? Colors.blue.withOpacity(0.3) 
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  spot.isAvailable ? 'Reserve' : 'Unavailable',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}