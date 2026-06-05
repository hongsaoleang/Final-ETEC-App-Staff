import 'package:bus_staff_scanner/models/user.dart';
import 'package:bus_staff_scanner/services/api_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bus_staff_scanner/config.dart';

class AuthService {
  final Dio _dio;
  AuthService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: apiBase,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 12),
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

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  String _messageFromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return 'Cannot connect to the API at $apiBase. Make sure Laravel is running and this device can reach that address.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401 || statusCode == 422) {
          return 'Invalid email or password.';
        }
        return 'Server returned ${statusCode ?? 'an error'}. Please try again.';
      case DioExceptionType.cancel:
        return 'Login request was cancelled.';
      case DioExceptionType.badCertificate:
        return 'The API SSL certificate is not trusted.';
      case DioExceptionType.unknown:
        return error.message ?? 'Login request failed.';
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );
      if (response.statusCode == 200) {
        final data = decodeApiResponse(response.data);
        if (data is! Map<String, dynamic>) {
          throw Exception('Invalid login response from server');
        }
        final token = data['access_token'] as String;
        await _saveToken(token);
        _dio.options.headers['Authorization'] = 'Bearer $token';
        final user = User.fromJson(data['user']);
        if (!user.roles.contains('staff') && !user.roles.contains('admin')) {
          await clearToken();
          throw Exception('This account is not a staff account');
        }
        return user;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      if (e is DioException) {
        throw Exception(_messageFromDio(e));
      }
      rethrow;
    }
    return null;
  }

  // Staff login might need to check role? We'll rely on backend to return appropriate user.
  // For simplicity, we use same login.

  Future<void> logout() async {
    await clearToken();
    _dio.options.headers.remove('Authorization');
  }

  Future<User?> getCurrentUser() async {
    try {
      final token = await _getToken();
      if (token == null) return null;
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.get('/me');
      if (response.statusCode == 200) {
        final data = decodeApiResponse(response.data);
        final userJson = data is Map<String, dynamic>
            ? data['user'] ?? data['data'] ?? data
            : data;
        if (userJson is Map<String, dynamic>) {
          final user = User.fromJson(userJson);
          if (user.roles.contains('staff') || user.roles.contains('admin')) {
            return user;
          }
        }
        await clearToken();
        return null;
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        await clearToken();
      }
      if (kDebugMode) {
        print('Get current user error: $e');
      }
    }
    return null;
  }
}
