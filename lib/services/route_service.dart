import 'package:bus_staff_scanner/config.dart';
import 'package:bus_staff_scanner/models/bus.dart';
import 'package:bus_staff_scanner/models/bus_route.dart';
import 'package:bus_staff_scanner/models/route_booking.dart';
import 'package:bus_staff_scanner/models/seat.dart';
import 'package:bus_staff_scanner/models/user.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RouteService {
  final Dio _dio;

  RouteService()
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

  Future<void> _setAuthHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  List<dynamic> _listFromResponse(dynamic responseData) {
    if (responseData is List) return responseData;
    if (responseData is Map<String, dynamic> && responseData['data'] is List) {
      return responseData['data'] as List<dynamic>;
    }
    return const [];
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

  Future<T> _request<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      if (e is DioException) {
        throw Exception(_messageFromDio(e));
      }
      rethrow;
    }
  }

  Future<List<Bus>> getBuses() async {
    return _request(() async {
      await _setAuthHeader();
      final response = await _dio.get('/buses');
      return _listFromResponse(
        response.data,
      ).map((json) => Bus.fromJson(json as Map<String, dynamic>)).toList();
    });
  }

  Future<List<BusRoute>> getRoutes() async {
    return _request(() async {
      await _setAuthHeader();
      final response = await _dio.get(
        '/bus-routes',
        queryParameters: {'include_all': true},
      );
      return _listFromResponse(
        response.data,
      ).map((json) => BusRoute.fromJson(json as Map<String, dynamic>)).toList();
    });
  }

  Future<BusRoute> createRoute({
    required String name,
    required String departureLocation,
    required String destination,
    required String departureTime,
    required String arrivalTime,
    required String date,
    required int busId,
    required double basePrice,
  }) async {
    return _request(() async {
      await _setAuthHeader();
      final response = await _dio.post(
        '/bus-routes',
        data: {
          'name': name,
          'departure_location': departureLocation,
          'destination': destination,
          'departure_time': departureTime,
          'arrival_time': arrivalTime,
          'date': date,
          'bus_id': busId,
          'base_price': basePrice,
          'status': 'scheduled',
        },
      );
      return BusRoute.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<BusRoute> updateRoute({
    required int id,
    required String name,
    required String departureLocation,
    required String destination,
    required String departureTime,
    required String arrivalTime,
    required String date,
    required int busId,
    required double basePrice,
    required String status,
  }) async {
    return _request(() async {
      await _setAuthHeader();
      final response = await _dio.put(
        '/bus-routes/$id',
        data: {
          'name': name,
          'departure_location': departureLocation,
          'destination': destination,
          'departure_time': departureTime,
          'arrival_time': arrivalTime,
          'date': date,
          'bus_id': busId,
          'base_price': basePrice,
          'status': status,
        },
      );
      return BusRoute.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<void> deleteRoute(int id) async {
    return _request(() async {
      await _setAuthHeader();
      await _dio.delete('/bus-routes/$id');
    });
  }

  Future<List<RouteBooking>> getRouteBookings(int routeId) async {
    return _request(() async {
      await _setAuthHeader();
      final response = await _dio.get('/staff/routes/$routeId/bookings');
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final bookings = data['bookings'] is List
          ? data['bookings'] as List<dynamic>
          : const <dynamic>[];

      return bookings
          .map((json) => RouteBooking.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  Future<RouteBooking> updateBookingStatus(int bookingId, String status) async {
    return _request(() async {
      await _setAuthHeader();
      final response = await _dio.patch(
        '/staff/bookings/$bookingId/status',
        data: {'status': status},
      );
      return RouteBooking.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<RouteBooking> cancelBooking(int bookingId) async {
    return _request(() async {
      await _setAuthHeader();
      final response = await _dio.delete('/staff/bookings/$bookingId');
      return RouteBooking.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<RouteBooking> createBooking({
    required int routeId,
    required int userId,
    required List<Map<String, dynamic>> seats,
    String status = 'confirmed',
  }) async {
    return _request(() async {
      await _setAuthHeader();
      final response = await _dio.post(
        '/staff/bookings',
        data: {
          'bus_route_id': routeId,
          'user_id': userId,
          'seats': seats,
          'status': status,
        },
      );
      return RouteBooking.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<RouteBooking> updateBooking({
    required int bookingId,
    int? userId,
    int? routeId,
    List<Map<String, dynamic>>? seats,
    String? status,
  }) async {
    return _request(() async {
      await _setAuthHeader();
      final data = <String, dynamic>{};
      if (userId != null) data['user_id'] = userId;
      if (routeId != null) data['bus_route_id'] = routeId;
      if (seats != null) data['seats'] = seats;
      if (status != null) data['status'] = status;

      final response = await _dio.put(
        '/staff/bookings/$bookingId',
        data: data,
      );
      return RouteBooking.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<List<Seat>> getRouteSeats(int routeId) async {
    return _request(() async {
      await _setAuthHeader();
      final response = await _dio.get('/bus-routes/$routeId');
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final bus = data['bus'] is Map<String, dynamic>
          ? data['bus'] as Map<String, dynamic>
          : <String, dynamic>{};
      final seats = bus['seats'] is List
          ? bus['seats'] as List<dynamic>
          : const <dynamic>[];
      return seats
          .map((json) => Seat.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<User>> searchPassengers(String query) async {
    if (query.length < 2) return [];
    return _request(() async {
      await _setAuthHeader();
      final response = await _dio.post(
        '/staff/search-passenger',
        data: {'query': query},
      );
      final data = response.data is List
          ? response.data as List<dynamic>
          : response.data['data'] ?? [];
      return data
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<User>> getPassengers({String? searchQuery}) async {
    if (searchQuery == null || searchQuery.length < 2) return [];
    return _request(() async {
      await _setAuthHeader();
      final response = await _dio.post(
        '/staff/search-passenger',
        data: {'query': searchQuery},
      );
      final data = response.data is List
          ? response.data as List<dynamic>
          : response.data['data'] ?? [];
      return data
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }
}
