import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bus_staff_scanner/config.dart';

class StatisticsService {
  final Dio _dio;
  StatisticsService()
    : _dio = Dio(
        BaseOptions(baseUrl: apiBase, headers: {'Accept': 'application/json'}),
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

  Future<Map<String, dynamic>> getBoardingStatistics() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Staff is not logged in. Please sign in first.');
    }

    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.get('/staff/boarding-statistics');

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Failed to load statistics');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Get statistics error: $e');
      }
      rethrow;
    }
  }

  // Additional methods for getting statistics by route, date range, etc.
}
