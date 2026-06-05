import 'package:bus_staff_scanner/models/user.dart';
import 'package:bus_staff_scanner/services/api_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bus_staff_scanner/config.dart';

class PassengerService {
  final Dio _dio;
  PassengerService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: apiBase,
          responseType: ResponseType.plain,
          headers: {'Accept': 'application/json'},
        ),
      ) {
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

  Future<List<User>> getPassengers({
    String? searchQuery,
    int? routeId,
    String? date,
  }) async {
    if (searchQuery == null || searchQuery.trim().length < 2) {
      return [];
    }

    try {
      final token = await _getToken();
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }

      final response = await _dio.post(
        '/staff/search-passenger',
        data: {'query': searchQuery.trim()},
      );

      if (response.statusCode == 200) {
        final dynamic responseData = decodeApiResponse(response.data);
        final List<dynamic> data = responseData is List
            ? responseData
            : responseData['data'] ?? [];
        return data
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load passengers');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Get passengers error: $e');
      }
      rethrow;
    }
  }

  // Additional methods for getting passenger details, etc.
}
