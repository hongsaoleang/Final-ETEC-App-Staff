import 'package:bus_staff_scanner/models/bus.dart';
import 'package:bus_staff_scanner/models/bus_route.dart';
import 'package:bus_staff_scanner/screens/route_ticket_screen.dart';
import 'package:bus_staff_scanner/services/route_service.dart';
import 'package:flutter/material.dart';

class RouteManagementScreen extends StatefulWidget {
  const RouteManagementScreen({super.key});

  @override
  State<RouteManagementScreen> createState() => _RouteManagementScreenState();
}

class _RouteManagementScreenState extends State<RouteManagementScreen> {
  final RouteService _routeService = RouteService();
  bool _isLoading = true;
  String? _errorMessage;
  List<BusRoute> _routes = [];
  List<Bus> _buses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _routeService.getRoutes(),
        _routeService.getBuses(),
      ]);
      if (!mounted) return;
      setState(() {
        _routes = results[0] as List<BusRoute>;
        _buses = results[1] as List<Bus>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load routes: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreateRouteSheet() async {
    if (_buses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a bus before creating a route.')),
      );
      return;
    }

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _RouteFormSheet(buses: _buses, routeService: _routeService),
    );

    if (created == true) {
      await _loadData();
    }
  }

  Future<void> _openEditRouteSheet(BusRoute route) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RouteFormSheet(
        buses: _buses,
        routeService: _routeService,
        route: route,
      ),
    );

    if (updated == true) {
      await _loadData();
    }
  }

  Future<void> _deleteRoute(BusRoute route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete route?'),
        content: Text(
          'Delete ${route.name}? Bookings connected to this route will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
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
      await _routeService.deleteRoute(route.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Route deleted')));
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete route: $e')));
    }
  }

  void _openBookings(BusRoute route) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => RouteTicketScreen(route: route)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routes'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateRouteSheet,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Add Route'),
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
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _routes.isEmpty
          ? const Center(child: Text('No routes have been added yet.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: _routes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final route = _routes[index];
                return Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.route),
                    title: Text(route.name),
                    subtitle: Text(
                      '${route.departureLocation} to ${route.destination}\n'
                      '${route.date} at ${route.departureTime} - ${route.arrivalTime}\n'
                      '${route.bus?.busNumber ?? 'No bus'} - \$${route.basePrice.toStringAsFixed(2)}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'bookings') {
                          _openBookings(route);
                        } else if (value == 'edit') {
                          _openEditRouteSheet(route);
                        } else if (value == 'delete') {
                          _deleteRoute(route);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'bookings',
                          child: ListTile(
                            leading: Icon(Icons.confirmation_number),
                            title: Text('Customer bookings'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit route'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete),
                            title: Text('Delete route'),
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _openBookings(route),
                  ),
                );
              },
            ),
    );
  }
}

class _RouteFormSheet extends StatefulWidget {
  const _RouteFormSheet({
    required this.buses,
    required this.routeService,
    this.route,
  });

  final List<Bus> buses;
  final RouteService routeService;
  final BusRoute? route;

  @override
  State<_RouteFormSheet> createState() => _RouteFormSheetState();
}

class _RouteFormSheetState extends State<_RouteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _departureController = TextEditingController();
  final _destinationController = TextEditingController();
  final _dateController = TextEditingController();
  final _departureTimeController = TextEditingController();
  final _arrivalTimeController = TextEditingController();
  final _priceController = TextEditingController();
  Bus? _selectedBus;
  String _selectedStatus = 'scheduled';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final route = widget.route;
    _selectedBus = route?.bus == null
        ? widget.buses.first
        : widget.buses.firstWhere(
            (bus) => bus.id == route!.bus!.id,
            orElse: () => widget.buses.first,
          );

    if (route != null) {
      _nameController.text = route.name;
      _departureController.text = route.departureLocation;
      _destinationController.text = route.destination;
      _dateController.text = _shortDate(route.date);
      _departureTimeController.text = _shortTime(route.departureTime);
      _arrivalTimeController.text = _shortTime(route.arrivalTime);
      _priceController.text = route.basePrice.toStringAsFixed(2);
      _selectedStatus = route.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departureController.dispose();
    _destinationController.dispose();
    _dateController.dispose();
    _departureTimeController.dispose();
    _arrivalTimeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    _dateController.text =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;
    controller.text =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedBus == null) return;

    setState(() => _isSaving = true);
    try {
      final route = widget.route;
      if (route == null) {
        await widget.routeService.createRoute(
          name: _nameController.text.trim(),
          departureLocation: _departureController.text.trim(),
          destination: _destinationController.text.trim(),
          departureTime: _departureTimeController.text.trim(),
          arrivalTime: _arrivalTimeController.text.trim(),
          date: _dateController.text.trim(),
          busId: _selectedBus!.id,
          basePrice: double.parse(_priceController.text.trim()),
        );
      } else {
        await widget.routeService.updateRoute(
          id: route.id,
          name: _nameController.text.trim(),
          departureLocation: _departureController.text.trim(),
          destination: _destinationController.text.trim(),
          departureTime: _departureTimeController.text.trim(),
          arrivalTime: _arrivalTimeController.text.trim(),
          date: _dateController.text.trim(),
          busId: _selectedBus!.id,
          basePrice: double.parse(_priceController.text.trim()),
          status: _selectedStatus,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save route: $e')));
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
                        widget.route == null ? 'Add Route' : 'Edit Route',
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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Route name',
                    prefixIcon: Icon(Icons.route),
                    border: OutlineInputBorder(),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _departureController,
                  decoration: const InputDecoration(
                    labelText: 'Departure location',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _destinationController,
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    prefixIcon: Icon(Icons.flag),
                    border: OutlineInputBorder(),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: const InputDecoration(
                    labelText: 'Travel date',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _departureTimeController,
                        readOnly: true,
                        onTap: () => _pickTime(_departureTimeController),
                        decoration: const InputDecoration(
                          labelText: 'Depart',
                          prefixIcon: Icon(Icons.schedule),
                          border: OutlineInputBorder(),
                        ),
                        validator: _required,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _arrivalTimeController,
                        readOnly: true,
                        onTap: () => _pickTime(_arrivalTimeController),
                        decoration: const InputDecoration(
                          labelText: 'Arrive',
                          prefixIcon: Icon(Icons.access_time_filled),
                          border: OutlineInputBorder(),
                        ),
                        validator: _required,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Bus>(
                  initialValue: _selectedBus,
                  decoration: const InputDecoration(
                    labelText: 'Bus',
                    prefixIcon: Icon(Icons.directions_bus),
                    border: OutlineInputBorder(),
                  ),
                  items: widget.buses
                      .map(
                        (bus) => DropdownMenuItem(
                          value: bus,
                          child: Text('${bus.busNumber} - ${bus.model}'),
                        ),
                      )
                      .toList(),
                  onChanged: (bus) => setState(() => _selectedBus = bus),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.event_available),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'scheduled',
                      child: Text('Scheduled'),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text('Cancelled'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedStatus = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ticket price',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_required(value) != null) return _required(value);
                    final parsed = double.tryParse(value!);
                    if (parsed == null || parsed < 0) {
                      return 'Enter a valid price';
                    }
                    return null;
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
                      widget.route == null ? 'Save Route' : 'Update Route',
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

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String _shortDate(String value) {
    if (value.length >= 10) return value.substring(0, 10);
    return value;
  }

  String _shortTime(String value) {
    if (value.length >= 5) return value.substring(0, 5);
    return value;
  }
}
