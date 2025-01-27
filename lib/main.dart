import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:floixemapp/auth/auth_service.dart';
import 'package:floixemapp/auth/login_screen.dart';
import 'package:floixemapp/home_screen.dart';
import 'package:floixemapp/models/user.dart'; // Importa el modelo User
import 'firebase_options.dart'; // Importa las opciones de Firebase
import 'package:url_strategy/url_strategy.dart'; // Importa el paquete url_strategy
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar si es web

void main() async {
  // Elimina el # de las URLs en Flutter Web
  setPathUrlStrategy();

  // Asegura que Flutter esté inicializado antes de ejecutar cualquier cosa
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con las opciones específicas de la plataforma
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa Hive
  await Hive.initFlutter();

  // Registra el adaptador para el modelo User
  Hive.registerAdapter(UserAdapter());

  // Abre la caja (box) para almacenar datos de usuario
  await Hive.openBox<User>('userBox');

  // Ejecuta la aplicación
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Floixem App', // Título de la aplicación
      theme: ThemeData(
        primarySwatch: Colors.deepOrange, // Color principal de la aplicación
        scaffoldBackgroundColor: Colors.white, // Fondo de las pantallas
      ),
      // Rutas de la aplicación
      routes: {
        '/login': (context) => const LoginScreen(), // Pantalla de inicio de sesión
        '/home': (context) => const HomeScreen(),   // Pantalla principal
      },
      // Ruta inicial (depende del estado de autenticación y la plataforma)
      home: AuthWrapper(),
    );
  }
}

/// Widget que maneja la lógica de autenticación
class AuthWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuthState(), // Verifica el estado de autenticación
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Muestra un indicador de carga mientras se verifica el estado de autenticación
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          // Muestra un mensaje de error si ocurre un problema
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        } else if (snapshot.data == true) {
          // Si el usuario está autenticado, redirige a la pantalla principal
          return const HomeScreen();
        } else {
          // Si el usuario no está autenticado, redirige a la pantalla de inicio de sesión
          return const LoginScreen();
        }
      },
    );
  }

  /// Verifica el estado de autenticación
  Future<bool> _checkAuthState() async {
    if (kIsWeb) {
      // En la web, no forzar el cierre de sesión al cargar la aplicación
      final isLoggedInOnline = await _authService.isUserLoggedInOnline();
      final isLoggedInOffline = await _authService.isUserLoggedInOffline();
      return isLoggedInOnline || isLoggedInOffline;
    } else {
      // En móviles, permitir el inicio de sesión offline
      final isLoggedInOnline = await _authService.isUserLoggedInOnline();
      final isLoggedInOffline = await _authService.isUserLoggedInOffline();
      return isLoggedInOnline || isLoggedInOffline;
    }
  }
}