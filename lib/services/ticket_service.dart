import 'package:bus_staff_scanner/models/ticket.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:bus_staff_scanner/config.dart';

class TicketService {
  final Dio _dio;
  TicketService() : _dio = Dio(BaseOptions(baseUrl: apiBase)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) {
          if (kDebugMode) {
            print('Dio error: ${e.message}');
          }
          handler.next(e);
        },
      ),
    );
  }

  Future<String?> _getToken() async {
    // TODO: Implement token retrieval from shared preferences
    // For now, we'll return null and handle unauthorized responses
    return null;
  }

  Future<Ticket?> verifyTicket(String qrCodeData) async {
    try {
      final token = await _getToken();
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }

      final response = await _dio.post(
        '/tickets/verify',
        data: {'qr_code_data': qrCodeData},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return Ticket.fromJson(data);
      } else {
        throw Exception('Invalid ticket');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Verify ticket error: $e');
      }
      rethrow;
    }
  }

  Future<bool> checkInTicket(int ticketId) async {
    try {
      final token = await _getToken();
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }

      final response = await _dio.post(
        '/check-ins',
        data: {'ticket_id': ticketId},
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) {
        print('Check in ticket error: $e');
      }
      rethrow;
    }
  }

  // Additional methods for fetching passenger info, etc.
}