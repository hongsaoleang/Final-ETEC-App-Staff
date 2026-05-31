import 'package:bus_staff_scanner/models/user.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bus_staff_scanner/config.dart';

class AuthService {
  final Dio _dio;
  AuthService() : _dio = Dio(BaseOptions(baseUrl: apiBase)) {
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

  Future<User?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );
      if (response.statusCode == 200) {
        final data = response.data;
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
        final resp = e.response?.data;
        if (resp is Map && resp['message'] != null) {
          throw Exception(resp['message']);
        }
        throw Exception(e.message);
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
        return User.fromJson(response.data);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Get current user error: $e');
      }
    }
    return null;
  }
}
