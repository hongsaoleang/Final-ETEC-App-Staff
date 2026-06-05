import 'package:flutter/material.dart';
import 'package:bus_staff_scanner/models/ticket.dart';

class TicketResultWidget extends StatelessWidget {
  final Ticket? ticket;
  final VoidCallback onCheckIn;

  const TicketResultWidget({
    super.key,
    required this.ticket,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    if (ticket == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text('Invalid ticket'),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 24),
            Text(
              'Ticket Verified',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.person,
              'Passenger Name',
              ticket!.passengerName ?? 'Unknown',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.email,
              'Email',
              ticket!.passengerEmail ?? 'Not provided',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.phone,
              'Phone',
              ticket!.passengerPhone ?? 'Not provided',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.route,
              'Route',
              ticket!.routeName ?? 'Not provided',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.flag,
              'Destination',
              ticket!.destination ?? 'Not provided',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.event_seat,
              'Seats',
              ticket!.seatNumbers ?? 'Not assigned',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.payments,
              'Payment',
              _formatStatus(ticket!.paymentStatus),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.info,
              'Booking',
              _formatStatus(ticket!.bookingStatus),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              ticket!.checkedIn ? Icons.verified : Icons.pending_actions,
              'Check-in',
              ticket!.checkedIn ? 'Checked in' : 'Not checked in',
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: ticket!.checkedIn ? null : onCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  ticket!.checkedIn
                      ? 'Already Checked In'
                      : 'Check In Passenger',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatStatus(String? status) {
    if (status == null || status.trim().isEmpty) return 'Unknown';
    return status
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
