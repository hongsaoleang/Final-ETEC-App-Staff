import 'package:bus_staff_scanner/models/bus_route.dart';
import 'package:bus_staff_scanner/models/route_booking.dart';
import 'package:bus_staff_scanner/models/seat.dart';
import 'package:bus_staff_scanner/models/user.dart';
import 'package:bus_staff_scanner/services/route_service.dart';
import 'package:flutter/material.dart';

class RouteTicketScreen extends StatefulWidget {
  const RouteTicketScreen({super.key, required this.route});

  final BusRoute route;

  @override
  State<RouteTicketScreen> createState() => _RouteTicketScreenState();
}

class _RouteTicketScreenState extends State<RouteTicketScreen> {
  final RouteService _routeService = RouteService();
  bool _isLoading = true;
  String? _errorMessage;
  List<RouteBooking> _bookings = [];
  List<Seat> _seats = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _loadSeats();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bookings = await _routeService.getRouteBookings(widget.route.id);
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

  Future<void> _loadSeats() async {
    try {
      final seats = await _routeService.getRouteSeats(widget.route.id);
      if (!mounted) return;
      setState(() => _seats = seats);
    } catch (e) {
      if (mounted) setState(() => _seats = []);
    }
  }

  Future<void> _updateBookingStatus(RouteBooking booking, String status) async {
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

  Future<void> _deleteBooking(RouteBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete booking?'),
        content: Text(
          'Delete ${booking.bookingReference} for ${booking.passengerName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _routeService.cancelBooking(booking.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking deleted')));
      await _loadBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete booking: $e')));
    }
  }

  Future<void> _openAddBookingSheet() async {
    await _loadSeats();

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BookingFormSheet(
        route: widget.route,
        routeService: _routeService,
        seats: _seats,
      ),
    );

    if (created == true) {
      await _loadBookings();
    }
  }

  Future<void> _openEditBookingSheet(RouteBooking booking) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BookingFormSheet(
        route: widget.route,
        routeService: _routeService,
        seats: _seats,
        booking: booking,
      ),
    );

    if (updated == true) {
      await _loadBookings();
    }
  }

  void _showBookingDetails(RouteBooking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                'Booking Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Passenger'),
                subtitle: Text('${booking.passengerName}\n${booking.passengerEmail}'),
              ),
              ListTile(
                leading: const Icon(Icons.confirmation_number),
                title: const Text('Booking Reference'),
                subtitle: Text(booking.bookingReference),
              ),
              ListTile(
                leading: const Icon(Icons.event_seat),
                title: const Text('Seats'),
                subtitle: Text(
                  booking.seats.isEmpty ? 'None' : booking.seats.join(', '),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Total Amount'),
                subtitle: Text('\$${booking.totalAmount.toStringAsFixed(2)}'),
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Status'),
                subtitle: Text(booking.status),
              ),
              ListTile(
                leading: const Icon(Icons.airplane_ticket),
                title: const Text('Ticket'),
                subtitle: Text(
                  booking.ticketNumber ?? 'Not issued',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.route.destination),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadBookings,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddBookingSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Booking'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(_errorMessage!, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBookings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_bus),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${widget.route.departureLocation} to ${widget.route.destination}\n'
                              '${widget.route.date} at ${widget.route.departureTime}',
                            ),
                          ),
                          Text('${_bookings.length} tickets'),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _bookings.isEmpty
                          ? const Center(
                              child: Text(
                                'No customer tickets for this route yet.',
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _bookings.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final booking = _bookings[index];
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
                                      color: booking.checkedIn
                                          ? Colors.green
                                          : Theme.of(context).colorScheme.primary,
                                    ),
                                    title: Text(booking.passengerName),
                                    subtitle: Text(
                                      '${booking.bookingReference} - ${booking.status}\n'
                                      'Ticket: ${booking.ticketNumber ?? 'Not issued'}\n'
                                      'Seats: ${booking.seats.isEmpty ? 'None' : booking.seats.join(', ')}',
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'delete') {
                                          _deleteBooking(booking);
                                        } else if (value == 'edit') {
                                          _openEditBookingSheet(booking);
                                        } else {
                                          _updateBookingStatus(booking, value);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: ListTile(
                                            leading: Icon(Icons.edit),
                                            title: Text('Edit booking'),
                                          ),
                                        ),
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
                                          value: 'delete',
                                          child: Text('Delete booking'),
                                        ),
                                      ],
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '\$${booking.totalAmount.toStringAsFixed(2)}',
                                          ),
                                          const Icon(Icons.more_vert),
                                        ],
                                      ),
                                    ),
                                    onTap: () => _showBookingDetails(booking),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _BookingFormSheet extends StatefulWidget {
  const _BookingFormSheet({
    required this.route,
    required this.routeService,
    required this.seats,
    this.booking,
  });

  final BusRoute route;
  final RouteService routeService;
  final List<Seat> seats;
  final RouteBooking? booking;

  @override
  State<_BookingFormSheet> createState() => _BookingFormSheetState();
}

class _BookingFormSheetState extends State<_BookingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  User? _selectedPassenger;
  List<Seat> _selectedSeats = [];
  String _selectedStatus = 'confirmed';
  bool _isSaving = false;
  bool _isSearching = false;
  List<User> _searchResults = [];
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    if (widget.booking != null) {
      _selectedStatus = widget.booking!.status;
      _selectedSeats = widget.seats.where((s) => widget.booking!.seats.contains(s.seatNumber)).toList();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPassengers(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final passengers = await widget.routeService.searchPassengers(query);
      if (!mounted) return;
      setState(() {
        _searchResults = passengers;
        if (passengers.isNotEmpty && _selectedPassenger == null) {
          _selectedPassenger = passengers.first;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _searchResults = []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() ||
        _selectedPassenger == null ||
        _selectedSeats.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final seatData = _selectedSeats
          .map((s) => {
                'seat_id': s.id,
                'price': widget.route.basePrice,
              })
          .toList();

      if (widget.booking == null) {
        await widget.routeService.createBooking(
          routeId: widget.route.id,
          userId: _selectedPassenger!.id,
          seats: seatData,
          status: _selectedStatus,
        );
      } else {
        await widget.routeService.updateBooking(
          bookingId: widget.booking!.id,
          userId: _selectedPassenger!.id,
          seats: seatData,
          status: _selectedStatus,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save booking: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.booking == null ? 'Add Booking' : 'Edit Booking',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search passenger',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: _searchPassengers,
                ),
                const SizedBox(height: 8),
                if (_isSearching)
                  const LinearProgressIndicator()
                else if (_searchResults.isNotEmpty)
                  DropdownButtonFormField<User>(
                    initialValue: _selectedPassenger,
                    decoration: const InputDecoration(
                      labelText: 'Passenger',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    items: _searchResults
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text('${p.name} (${p.email})'),
                          ),
                        )
                        .toList(),
                    onChanged: (p) => setState(() => _selectedPassenger = p),
                    validator: (value) => value == null ? 'Select a passenger' : null,
                  ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Seats',
                    prefixIcon: Icon(Icons.event_seat),
                    border: OutlineInputBorder(),
                  ),
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 8,
                        children: _selectedSeats
                            .map((s) => Chip(
                                  label: Text(s.seatNumber),
                                  onDeleted: () {
                                    setState(() => _selectedSeats.remove(s));
                                  },
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          itemCount: widget.seats.length,
                          itemBuilder: (context, index) {
                            final seat = widget.seats[index];
                            final isSelected = _selectedSeats.any(
                                (s) => s.id == seat.id || s.seatNumber == seat.seatNumber);
                            return CheckboxListTile(
                              title: Text(seat.seatNumber),
                              value: isSelected,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedSeats.add(seat);
                                  } else {
                                    _selectedSeats.removeWhere((s) => s.id == seat.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.info),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedStatus = value);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      widget.booking == null ? 'Create Booking' : 'Update Booking',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}