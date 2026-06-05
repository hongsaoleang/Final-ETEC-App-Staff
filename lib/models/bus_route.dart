import 'package:bus_staff_scanner/models/bus.dart';

class BusRoute {
  final int id;
  final String name;
  final String departureLocation;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final String date;
  final Bus? bus;
  final double basePrice;
  final int? availableSeats;
  final String status;

  BusRoute({
    required this.id,
    required this.name,
    required this.departureLocation,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.date,
    this.bus,
    required this.basePrice,
    this.availableSeats,
    required this.status,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      departureLocation: json['departure_location'] ?? '',
      destination: json['destination'] ?? '',
      departureTime: _shortTime(json['departure_time']),
      arrivalTime: _shortTime(json['arrival_time']),
      date: _shortDate(json['date']),
      bus: json['bus'] is Map<String, dynamic>
          ? Bus.fromJson(json['bus'])
          : null,
      basePrice: double.tryParse('${json['base_price'] ?? 0}') ?? 0,
      availableSeats: int.tryParse('${json['available_seats'] ?? ''}'),
      status: json['status'] ?? 'scheduled',
    );
  }
}

String _shortDate(dynamic value) {
  final text = value?.toString() ?? '';
  if (text.length >= 10) return text.substring(0, 10);
  return text;
}

String _shortTime(dynamic value) {
  final text = value?.toString() ?? '';
  if (text.length >= 5) return text.substring(0, 5);
  return text;
}
