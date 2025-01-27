import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Clases propias
import 'package:floixemapp/auth/auth_service.dart';
import 'package:floixemapp/models/user.dart';
import 'package:floixemapp/auth/login_screen.dart';
import 'package:floixemapp/home_screen.dart';

// Opciones de Firebase generadas por flutterfire configure
import 'firebase_options.dart';

// Para eliminar el # de la URL en Flutter Web
import 'package:url_strategy/url_strategy.dart';

void main() async {
  // Elimina el # en las URL de Flutter Web
  setPathUrlStrategy();

  // Asegura la inicialización de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con las opciones generadas
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa Hive e registra el adaptador para User
  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());
  await Hive.openBox<User>('userBox');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'La casa del suelo radiante app',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: Colors.white,
      ),
      // Definimos rutas
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
      },
      // La pantalla inicial dependerá de la autenticación
      home: AuthWrapper(),
    );
  }
}

/// Widget que envuelve la lógica de ver si hay sesión o no
class AuthWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuthState(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Muestra un loader mientras verifica
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          // Muestra un mensaje de error si algo sale mal
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        } else {
          // snapshot.data es true/false
          final isLoggedIn = snapshot.data ?? false;
          if (isLoggedIn) {
            // Si hay sesión en Firebase, ir a Home
            return const HomeScreen();
          } else {
            // Si no hay sesión, ir a Login
            return const LoginScreen();
          }
        }
      },
    );
  }

  /// Verifica si hay usuario logueado. En Web ignoramos el offline.
  Future<bool> _checkAuthState() async {
    // Si estamos en Web, solo confiar en FirebaseAuth (online)
    if (kIsWeb) {
      final currentUser = _authService.auth.currentUser;
      if (currentUser == null) {
        // Borramos cualquier usuario local para no confundir
        await _authService.clearLocalUser();
        return false;
      } else {
        return true;
      }
    } else {
      // En móvil combinamos online y offline
      final isOnline = await _authService.isUserLoggedInOnline();
      final isOffline = await _authService.isUserLoggedInOffline();
      return isOnline || isOffline;
    }
  }
}
