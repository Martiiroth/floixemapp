import 'package:flutter/material.dart';
import 'package:floixemapp/auth/auth_service.dart';
import 'package:floixemapp/home_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Importa connectivity_plus

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // Si hay conexión a Internet, intenta iniciar sesión con Google
        final user = await _auth.signInWithGoogle();
        if (user != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al iniciar sesión con Google.")),
          );
        }
      } else {
        // Si no hay conexión a Internet, verifica si hay datos locales
        final isLoggedIn = await _auth.isUserLoggedInOffline();
        if (isLoggedIn && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No se encontraron datos locales.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error durante el inicio de sesión: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Centrar contenido principal
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título "FLOIXEM" ajustado
                const SizedBox(height: 20),
                const Text(
                  "FLOIXEM",
                  style: TextStyle(
                    fontSize: 80, // Aumentado para hacerlo más grande
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 70), // Más espacio entre el texto y el botón
                // Botón de inicio de sesión
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  child: const Text(
                    "Login with Google",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Barra roja decorativa en la parte inferior
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 80,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}