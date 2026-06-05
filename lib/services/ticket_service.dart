import 'package:bus_staff_scanner/models/ticket.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:bus_staff_scanner/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  String _messageFromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      if (data['message'] != null) return data['message'].toString();
      final errors = data['errors'];
      if (errors is Map) {
        final messages = errors.values
            .expand((value) => value is List ? value : [value])
            .map((value) => value.toString())
            .toList();
        if (messages.isNotEmpty) return messages.join('\n');
      }
    }
    return error.message ?? 'Request failed';
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
      if (e is DioException) {
        throw Exception(_messageFromDio(e));
      }
      rethrow;
    }
  }

  Future<bool> checkInTicket(String ticketNumber) async {
    try {
      final token = await _getToken();
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }

      final response = await _dio.post(
        '/check-ins',
        data: {'ticket_number': ticketNumber},
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) {
        print('Check in ticket error: $e');
      }
      if (e is DioException) {
        throw Exception(_messageFromDio(e));
      }
      rethrow;
    }
  }

  // Additional methods for fetching passenger info, etc.
}
