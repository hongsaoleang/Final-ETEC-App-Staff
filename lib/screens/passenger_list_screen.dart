import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bus_staff_scanner/models/user.dart';
import 'package:bus_staff_scanner/services/passenger_service.dart';

class PassengerListScreen extends StatefulWidget {
  const PassengerListScreen({super.key});

  @override
  State<PassengerListScreen> createState() => _PassengerListScreenState();
}

class _PassengerListScreenState extends State<PassengerListScreen> {
  bool _isLoading = true;
  List<User> _passengers = [];
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  final PassengerService _passengerService = PassengerService();

  @override
  void initState() {
    super.initState();
    _loadPassengers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPassengers() async {
    if (_searchQuery.trim().length < 2) {
      if (!mounted) return;
      setState(() {
        _passengers = [];
        _errorMessage = _searchQuery.isEmpty
            ? null
            : 'Please enter at least 2 characters to search passengers.';
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final passengers = await _passengerService.getPassengers(
        searchQuery: _searchQuery,
      );

      if (!mounted) return;
      setState(() {
        _passengers = passengers;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load passengers: $e';
        _isLoading = false;
      });
    }
  }

  void _searchPassengers(String query) {
    setState(() {
      _searchQuery = query;
    });
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _loadPassengers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passenger List'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search passengers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _searchPassengers,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $_errorMessage'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPassengers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _passengers.isEmpty
          ? Center(
              child: Text(
                _searchQuery.trim().length < 2
                    ? 'Enter at least 2 characters to search passengers.'
                    : 'No passengers found',
              ),
            )
          : ListView.builder(
              itemCount: _passengers.length,
              itemBuilder: (context, index) {
                final passenger = _passengers[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      passenger.name.isNotEmpty
                          ? passenger.name[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(passenger.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email: ${passenger.email}',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Phone: ${passenger.phoneNumber ?? 'Not provided'}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Viewing details for ${passenger.name}'),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
