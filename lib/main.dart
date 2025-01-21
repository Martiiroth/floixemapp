import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:floixemapp/auth/auth_service.dart';
import 'package:floixemapp/auth/login_screen.dart';
import 'package:floixemapp/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Inicializar Firebase
  final authService = AuthService();
  final isLoggedInOffline = await authService.isUserLoggedInOffline();
  runApp(MyApp(isLoggedInOffline: isLoggedInOffline));
}

class MyApp extends StatelessWidget {
  final bool isLoggedInOffline;

  const MyApp({super.key, required this.isLoggedInOffline});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Offline App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isLoggedInOffline ? const HomeScreen() : const LoginScreen(),
    );
  }
}
