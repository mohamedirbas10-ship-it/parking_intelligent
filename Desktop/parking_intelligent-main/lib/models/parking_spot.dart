class ParkingSpot {
  final String id;
  final String name;
  final bool isAvailable;
  final DateTime? reservationTime;
  final int validityHours;
  final String? qrCode;
  final String? userId;
  final String? userName;

  ParkingSpot({
    required this.id,
    required this.name,
    required this.isAvailable,
    this.reservationTime,
    required this.validityHours,
    this.qrCode,
    this.userId,
    this.userName,
  });

  ParkingSpot copyWith({
    String? id,
    String? name,
    bool? isAvailable,
    DateTime? reservationTime,
    int? validityHours,
    String? qrCode,
    String? userId,
    String? userName,
  }) {
    return ParkingSpot(
      id: id ?? this.id,
      name: name ?? this.name,
      isAvailable: isAvailable ?? this.isAvailable,
      reservationTime: reservationTime ?? this.reservationTime,
      validityHours: validityHours ?? this.validityHours,
      qrCode: qrCode ?? this.qrCode,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
    );
  }

  bool get isExpired {
    if (reservationTime == null) return false;
    final now = DateTime.now();
    final expiryTime = reservationTime!.add(Duration(hours: validityHours));
    return now.isAfter(expiryTime);
  }

  String get timeRemaining {
    if (reservationTime == null) return '';
    final now = DateTime.now();
    final expiryTime = reservationTime!.add(Duration(hours: validityHours));
    final difference = expiryTime.difference(now);
    
    if (difference.isNegative) return 'Expired';
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
