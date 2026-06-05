class Ticket {
  final int id;
  final String ticketNumber;
  final String? passengerName;
  final String? passengerEmail;
  final String? passengerPhone;
  final String? routeName;
  final String? destination;
  final String? seatNumbers;
  final String? bookingStatus;
  final String? paymentStatus;
  final bool checkedIn;

  Ticket({
    required this.id,
    required this.ticketNumber,
    this.passengerName,
    this.passengerEmail,
    this.passengerPhone,
    this.routeName,
    this.destination,
    this.seatNumbers,
    this.bookingStatus,
    this.paymentStatus,
    this.checkedIn = false,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'] is Map<String, dynamic>
        ? json['booking'] as Map<String, dynamic>
        : <String, dynamic>{};
    final user = booking['user'] is Map<String, dynamic>
        ? booking['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    final route = booking['bus_route'] is Map<String, dynamic>
        ? booking['bus_route'] as Map<String, dynamic>
        : <String, dynamic>{};
    final payment = booking['payment'] is Map<String, dynamic>
        ? booking['payment'] as Map<String, dynamic>
        : <String, dynamic>{};
    final details = booking['booking_details'] is List
        ? booking['booking_details'] as List<dynamic>
        : const <dynamic>[];
    final seatNumbers = details
        .map((detail) {
          if (detail is! Map<String, dynamic>) return '';
          final seat = detail['seat'];
          if (seat is Map<String, dynamic>) {
            return '${seat['seat_number'] ?? ''}';
          }
          return '';
        })
        .where((seat) => seat.isNotEmpty)
        .join(', ');

    return Ticket(
      id: json['id'] ?? 0,
      ticketNumber: json['ticket_number'] ?? '',
      passengerName: json['passenger_name'] ?? user['name'],
      passengerEmail: json['passenger_email'] ?? user['email'],
      passengerPhone: json['passenger_phone'] ?? user['phone_number'],
      routeName: route['name'],
      destination: route['destination'],
      seatNumbers: seatNumbers.isEmpty ? null : seatNumbers,
      bookingStatus: json['booking_status'] ?? booking['status'],
      paymentStatus:
          json['payment_status'] ??
          booking['payment_status'] ??
          payment['status'],
      checkedIn: json['check_in'] != null,
    );
  }
}
