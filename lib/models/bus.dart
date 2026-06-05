import 'package:bus_staff_scanner/models/seat.dart';

class Bus {
  final int id;
  final String busNumber;
  final String model;
  final int capacity;
  final String type;
  final String status;
  final List<Seat> seats;

  Bus({
    required this.id,
    required this.busNumber,
    required this.model,
    required this.capacity,
    required this.type,
    required this.status,
    this.seats = const [],
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'] ?? 0,
      busNumber: json['bus_number'] ?? '',
      model: json['model'] ?? '',
      capacity: json['capacity'] ?? 0,
      type: json['type'] ?? '',
      status: json['status'] ?? 'active',
      seats: json['seats'] is List
          ? (json['seats'] as List<dynamic>)
              .map((s) => Seat.fromJson(s as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}
