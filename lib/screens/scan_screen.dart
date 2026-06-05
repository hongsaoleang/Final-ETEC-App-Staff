import 'dart:async';
import 'dart:convert';

import 'package:bus_staff_scanner/models/ticket.dart';
import 'package:bus_staff_scanner/screens/scan_history_screen.dart';
import 'package:bus_staff_scanner/services/ticket_service.dart';
import 'package:bus_staff_scanner/widgets/ticket_result_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  static const _historyKey = 'scan_history';

  final TicketService _ticketService = TicketService();
  final ImagePicker _imagePicker = ImagePicker();
  final MobileScannerController _controller = MobileScannerController(
    autoStart: true,
    detectionSpeed: DetectionSpeed.noDuplicates,
    detectionTimeoutMs: 1200,
    formats: const [BarcodeFormat.qrCode],
    autoZoom: true,
  );

  bool _isProcessing = false;
  String? _lastCode;
  DateTime? _lastScanAt;
  String? _errorMessage;
  String? _lastResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.hasCameraPermission) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_isProcessing) unawaited(_controller.start());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_controller.stop());
    }
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    final code = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .firstOrNull;
    if (code == null || _shouldIgnoreDuplicate(code)) return;
    await _processCode(code, source: 'Camera');
  }

  bool _shouldIgnoreDuplicate(String code) {
    final now = DateTime.now();
    if (_isProcessing) return true;
    if (_lastCode == code &&
        _lastScanAt != null &&
        now.difference(_lastScanAt!) < const Duration(seconds: 4)) {
      return true;
    }
    _lastCode = code;
    _lastScanAt = now;
    return false;
  }

  Future<void> _processCode(String code, {required String source}) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _lastResult = code;
    });
    await _controller.stop();

    try {
      final ticket = await _ticketService.verifyTicket(code);
      await _addHistory(
        code: code,
        source: source,
        status: 'verified',
        ticket: ticket,
      );
      if (!mounted) return;
      setState(() => _isProcessing = false);

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => TicketResultWidget(
          ticket: ticket,
          onCheckIn: () async {
            Navigator.of(context).pop();
            if (ticket != null) {
              await _checkInTicket(
                ticket.ticketNumber,
                code: code,
                source: source,
              );
            }
          },
        ),
      );
    } catch (e) {
      await _addHistory(
        code: code,
        source: source,
        status: 'failed',
        message: _cleanError(e),
      );
      if (!mounted) return;
      setState(() {
        _errorMessage = _cleanError(e);
        _isProcessing = false;
      });
    }
  }

  Future<void> _checkInTicket(
    String ticketNumber, {
    required String code,
    required String source,
  }) async {
    setState(() => _isProcessing = true);
    try {
      final success = await _ticketService.checkInTicket(ticketNumber);
      await _addHistory(
        code: code,
        source: source,
        status: success ? 'checked_in' : 'check_in_failed',
      );
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Passenger checked in successfully'
                : 'Failed to check in passenger',
          ),
        ),
      );
    } catch (e) {
      await _addHistory(
        code: code,
        source: source,
        status: 'check_in_failed',
        message: _cleanError(e),
      );
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = _cleanError(e);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking in passenger: ${_cleanError(e)}'),
        ),
      );
    }
  }

  Future<void> _scanFromGallery() async {
    if (_isProcessing) return;
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    await _controller.stop();

    try {
      final capture = await _controller.analyzeImage(
        image.path,
        formats: const [BarcodeFormat.qrCode],
      );
      final code = capture?.barcodes
          .map((barcode) => barcode.rawValue?.trim())
          .whereType<String>()
          .where((value) => value.isNotEmpty)
          .firstOrNull;
      if (code == null) {
        throw Exception('No QR code was found in that image.');
      }
      await _processCode(code, source: 'Gallery');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  Future<void> _openManualEntry() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Entry'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Booking or QR code',
            prefixIcon: Icon(Icons.keyboard),
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.isEmpty) return;
    await _processCode(code, source: 'Manual');
  }

  Future<void> _resumeCamera() async {
    setState(() {
      _isProcessing = false;
      _errorMessage = null;
      _lastResult = null;
    });
    await _controller.start();
  }

  Future<void> _addHistory({
    required String code,
    required String source,
    required String status,
    Ticket? ticket,
    String? message,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_historyKey) ?? const [];
    final entry = {
      'code': code,
      'source': source,
      'status': status,
      'message': message,
      'ticket_number': ticket?.ticketNumber,
      'passenger_name': ticket?.passengerName,
      'payment_status': ticket?.paymentStatus,
      'checked_in': ticket?.checkedIn,
      'scanned_at': DateTime.now().toIso8601String(),
    };
    final updated = [jsonEncode(entry), ...existing].take(80).toList();
    await prefs.setStringList(_historyKey, updated);
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Ticket'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Scan history',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScanHistoryScreen()),
              );
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _handleBarcode),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Row(
                  children: [
                    IconButton(
                      tooltip: 'Toggle flash',
                      icon: Icon(
                        state.torchState == TorchState.on
                            ? Icons.flash_on
                            : Icons.flash_off,
                        color: Colors.white,
                      ),
                      onPressed: state.isInitialized
                          ? () => _controller.toggleTorch()
                          : null,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Switch camera',
                      icon: const Icon(Icons.cameraswitch, color: Colors.white),
                      onPressed: state.isInitialized
                          ? () => _controller.switchCamera()
                          : null,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: _buildBottomPanel(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isProcessing)
              const LinearProgressIndicator()
            else
              Text(
                _errorMessage ??
                    (_lastResult == null
                        ? 'Point the camera at a ticket QR code'
                        : 'Last scan: $_lastResult'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _errorMessage == null ? Colors.white : Colors.red[200],
                  fontSize: 15,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _scanFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _openManualEntry,
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Manual'),
                  ),
                ),
              ],
            ),
            if (_errorMessage != null || _lastResult != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isProcessing ? null : _resumeCamera,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Again'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
