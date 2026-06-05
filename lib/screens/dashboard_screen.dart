import 'package:bus_staff_scanner/models/route_booking.dart';
import 'package:bus_staff_scanner/services/route_service.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final RouteService _routeService = RouteService();
  bool _isLoading = true;
  String? _errorMessage;
  int _routeCount = 0;
  int _busCount = 0;
  List<RouteBooking> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _routeService.getRoutes(),
        _routeService.getBuses(),
        _routeService.getAllBookings(),
      ]);
      if (!mounted) return;
      setState(() {
        _routeCount = (results[0] as List).length;
        _busCount = (results[1] as List).length;
        _bookings = results[2] as List<RouteBooking>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load dashboard: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkedIn = _bookings.where((booking) => booking.checkedIn).length;
    final paid = _bookings
        .where((booking) => booking.paymentStatus.toLowerCase() == 'paid')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_errorMessage!, textAlign: TextAlign.center),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatTile(
                        label: 'Bookings',
                        value: '${_bookings.length}',
                        icon: Icons.confirmation_number,
                        color: Colors.indigo,
                      ),
                      _StatTile(
                        label: 'Checked In',
                        value: '$checkedIn',
                        icon: Icons.verified,
                        color: Colors.green,
                      ),
                      _StatTile(
                        label: 'Paid',
                        value: '$paid',
                        icon: Icons.payments,
                        color: Colors.teal,
                      ),
                      _StatTile(
                        label: 'Routes',
                        value: '$_routeCount',
                        icon: Icons.route,
                        color: Colors.deepOrange,
                      ),
                      _StatTile(
                        label: 'Buses',
                        value: '$_busCount',
                        icon: Icons.directions_bus,
                        color: Colors.blueGrey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Recent Bookings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_bookings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('No bookings yet.')),
                    )
                  else
                    ..._bookings
                        .take(8)
                        .map(
                          (booking) => Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: Icon(
                                booking.checkedIn
                                    ? Icons.check_circle
                                    : Icons.pending_actions,
                                color: booking.checkedIn
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              title: Text(booking.passengerName),
                              subtitle: Text(
                                '${booking.bookingReference} - ${booking.status}\n'
                                'Payment: ${_formatStatus(booking.paymentStatus)}',
                              ),
                              trailing: Text(
                                '\$${booking.totalAmount.toStringAsFixed(2)}',
                              ),
                            ),
                          ),
                        ),
                ],
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
