import 'package:flutter/material.dart';
import 'package:bus_staff_scanner/services/statistics_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};
  String? _errorMessage;
  final StatisticsService _statisticsService = StatisticsService();

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final statistics = await _statisticsService.getBoardingStatistics();

      if (!mounted) return;
      setState(() {
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load statistics: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boarding Statistics'),
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
                        onPressed: _loadStatistics,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _statistics.isEmpty
                  ? const Center(
                      child: Text('No statistics available'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatCard(
                            'Total Passengers',
                            _statistics['total_passengers'] ?? 0,
                            Icons.people,
                            Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            'Checked In',
                            _statistics['checked_in'] ?? 0,
                            Icons.check_circle,
                            Colors.green,
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            'Pending',
                            _statistics['pending'] ?? 0,
                            Icons.pending_actions,
                            Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            'Completion Rate',
                            '${_toDouble(_statistics['completion_rate']).toStringAsFixed(1)}%',
                            Icons.show_chart,
                            Colors.purple,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Today\'s Boardings',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _buildBoardingsList(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildStatCard(String label, dynamic value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardingsList() {
    final boardings = (_statistics['recent_boardings'] as List? ?? [])
        .whereType<Map>()
        .map((boarding) => Map<String, dynamic>.from(boarding))
        .toList();

    if (boardings.isEmpty) {
      return const Text('No recent boardings');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: boardings.length,
      itemBuilder: (context, index) {
        final boarding = boardings[index];
        return ListTile(
          leading: const Icon(Icons.access_time, color: Colors.grey),
          title: Text(boarding['passenger_name'] ?? 'Unknown Passenger'),
          subtitle: Text(
            '${boarding['route_name'] ?? 'Unknown Route'} - ${boarding['time'] ?? 'Unknown Time'}',
            style: TextStyle(fontSize: 12),
          ),
          trailing: Icon(
            boarding['status'] == 'checked_in' ? Icons.check_circle : Icons.access_time,
            color: boarding['status'] == 'checked_in' ? Colors.green : Colors.grey,
          ),
        );
      },
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
