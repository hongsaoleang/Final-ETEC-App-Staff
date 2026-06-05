class Seat {
  final int id;
  final int busId;
  final String seatNumber;
  final String type;
  final String status;

  Seat({
    required this.id,
    required this.busId,
    required this.seatNumber,
    required this.type,
    required this.status,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['id'] ?? 0,
      busId: json['bus_id'] ?? 0,
      seatNumber: json['seat_number'] ?? '',
      type: json['type'] ?? 'standard',
      status: json['status'] ?? 'available',
    );
  }
}