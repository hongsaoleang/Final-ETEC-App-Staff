import 'package:flutter/foundation.dart';

// Central API base URL for the staff scanner app.
// For Android emulator use: http://10.0.2.2:8000/api
// For iOS simulator / web / host machine use: http://127.0.0.1:8000/api
// For a physical device replace with your machine IP, e.g. http://192.168.1.100:8000/api
final String apiBase = kIsWeb
    ? 'http://127.0.0.1:8000/api'
    : 'http://10.0.2.2:8000/api';
