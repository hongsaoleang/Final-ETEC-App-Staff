import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bus_staff_scanner/providers/auth_provider.dart';
import 'package:bus_staff_scanner/screens/splash_screen.dart';
import 'package:bus_staff_scanner/screens/login_screen.dart';
import 'package:bus_staff_scanner/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Add other providers here
      ],
      child: MaterialApp(
        title: 'Bus Staff Scanner',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          // Add more routes as needed
        },
      ),
    );
  }
}
