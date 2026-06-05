class RouteBooking {
  final int id;
  final String bookingReference;
  final String passengerName;
  final String passengerEmail;
  final String? passengerPhone;
  final String status;
  final String paymentStatus;
  final double totalAmount;
  final String? ticketNumber;
  final bool checkedIn;
  final List<String> seats;

  RouteBooking({
    required this.id,
    required this.bookingReference,
    required this.passengerName,
    required this.passengerEmail,
    this.passengerPhone,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    this.ticketNumber,
    required this.checkedIn,
    required this.seats,
  });

  factory RouteBooking.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    final ticket = json['ticket'] is Map<String, dynamic>
        ? json['ticket'] as Map<String, dynamic>
        : <String, dynamic>{};
    final payment = json['payment'] is Map<String, dynamic>
        ? json['payment'] as Map<String, dynamic>
        : <String, dynamic>{};
    final details = json['booking_details'] is List
        ? json['booking_details'] as List<dynamic>
        : const <dynamic>[];

    return RouteBooking(
      id: json['id'] ?? 0,
      bookingReference: json['booking_reference'] ?? '',
      passengerName: user['name'] ?? 'Unknown passenger',
      passengerEmail: user['email'] ?? '',
      passengerPhone: user['phone_number'],
      status: json['status'] ?? '',
      paymentStatus: json['payment_status'] ?? payment['status'] ?? 'unknown',
      totalAmount: double.tryParse('${json['total_amount'] ?? 0}') ?? 0,
      ticketNumber: ticket['ticket_number'],
      checkedIn: ticket['check_in'] != null,
      seats: details
          .map((detail) {
            if (detail is! Map<String, dynamic>) return '';
            final seat = detail['seat'];
            if (seat is Map<String, dynamic>) {
              return '${seat['seat_number'] ?? ''}';
            }
            return '';
          })
          .where((seat) => seat.isNotEmpty)
          .toList(),
    );
  }
}
