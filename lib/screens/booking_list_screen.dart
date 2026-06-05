import 'package:bus_staff_scanner/models/route_booking.dart';
import 'package:bus_staff_scanner/services/route_service.dart';
import 'package:flutter/material.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  final RouteService _routeService = RouteService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  String _statusFilter = 'all';
  String _paymentFilter = 'all';
  String _query = '';
  List<RouteBooking> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final bookings = await _routeService.getAllBookings();
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load bookings: $e';
        _isLoading = false;
      });
    }
  }

  List<RouteBooking> get _filteredBookings {
    final query = _query.toLowerCase().trim();
    return _bookings.where((booking) {
      final matchesSearch =
          query.isEmpty ||
          booking.passengerName.toLowerCase().contains(query) ||
          booking.passengerEmail.toLowerCase().contains(query) ||
          booking.bookingReference.toLowerCase().contains(query) ||
          (booking.ticketNumber ?? '').toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == 'all' || booking.status == _statusFilter;
      final matchesPayment =
          _paymentFilter == 'all' ||
          booking.paymentStatus.toLowerCase() == _paymentFilter;
      return matchesSearch && matchesStatus && matchesPayment;
    }).toList();
  }

  Future<void> _updateStatus(RouteBooking booking, String status) async {
    try {
      await _routeService.updateBookingStatus(booking.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Booking marked $status')));
      await _loadBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update booking: $e')));
    }
  }

  void _showDetails(RouteBooking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Booking Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _DetailTile(
              icon: Icons.person,
              label: 'Passenger',
              value: '${booking.passengerName}\n${booking.passengerEmail}',
            ),
            _DetailTile(
              icon: Icons.phone,
              label: 'Phone',
              value: booking.passengerPhone ?? 'Not provided',
            ),
            _DetailTile(
              icon: Icons.confirmation_number,
              label: 'Booking Reference',
              value: booking.bookingReference,
            ),
            _DetailTile(
              icon: Icons.airplane_ticket,
              label: 'Ticket',
              value: booking.ticketNumber ?? 'Not issued',
            ),
            _DetailTile(
              icon: Icons.event_seat,
              label: 'Seats',
              value: booking.seats.isEmpty ? 'None' : booking.seats.join(', '),
            ),
            _DetailTile(
              icon: Icons.payments,
              label: 'Payment Status',
              value: _formatStatus(booking.paymentStatus),
            ),
            _DetailTile(
              icon: booking.checkedIn ? Icons.verified : Icons.pending_actions,
              label: 'Check-in Status',
              value: booking.checkedIn ? 'Checked in' : 'Not checked in',
            ),
            _DetailTile(
              icon: Icons.info,
              label: 'Booking Status',
              value: _formatStatus(booking.status),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBookings;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Bookings'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadBookings,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(136),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search name, email, booking, ticket',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Booking',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem(
                            value: 'confirmed',
                            child: Text('Confirmed'),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('Completed'),
                          ),
                          DropdownMenuItem(
                            value: 'cancelled',
                            child: Text('Cancelled'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _statusFilter = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _paymentFilter,
                        decoration: const InputDecoration(
                          labelText: 'Payment',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(value: 'paid', child: Text('Paid')),
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem(
                            value: 'failed',
                            child: Text('Failed'),
                          ),
                          DropdownMenuItem(
                            value: 'refunded',
                            child: Text('Refunded'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _paymentFilter = value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, textAlign: TextAlign.center))
          : filtered.isEmpty
          ? const Center(child: Text('No bookings match your filters.'))
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final booking = filtered[index];
                  return Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: Icon(
                        booking.checkedIn
                            ? Icons.check_circle
                            : Icons.confirmation_number,
                        color: booking.checkedIn ? Colors.green : Colors.indigo,
                      ),
                      title: Text(booking.passengerName),
                      subtitle: Text(
                        '${booking.bookingReference} - ${_formatStatus(booking.status)}\n'
                        'Payment: ${_formatStatus(booking.paymentStatus)} - '
                        'Check-in: ${booking.checkedIn ? 'Done' : 'Pending'}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) => _updateStatus(booking, value),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'pending',
                            child: Text('Mark pending'),
                          ),
                          PopupMenuItem(
                            value: 'confirmed',
                            child: Text('Mark confirmed'),
                          ),
                          PopupMenuItem(
                            value: 'completed',
                            child: Text('Mark completed'),
                          ),
                          PopupMenuItem(
                            value: 'cancelled',
                            child: Text('Mark cancelled'),
                          ),
                        ],
                      ),
                      onTap: () => _showDetails(booking),
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _formatStatus(String value) {
    return value
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
