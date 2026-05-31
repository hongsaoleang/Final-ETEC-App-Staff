class Ticket {
  final int id;
  final String? passengerName;
  final String? passengerEmail;
  final String? passengerPhone;

  Ticket({
    required this.id,
    this.passengerName,
    this.passengerEmail,
    this.passengerPhone,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] ?? 0,
      passengerName: json['passenger_name'],
      passengerEmail: json['passenger_email'],
      passengerPhone: json['passenger_phone'],
    );
  }
}