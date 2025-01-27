import 'package:flutter/material.dart';
import 'package:floixemapp/auth/auth_service.dart';
import 'package:floixemapp/screens/nuevo_servicio_screen.dart';
import 'package:floixemapp/screens/clientes_screen.dart';
import 'package:floixemapp/screens/historial_screen.dart';
import 'package:floixemapp/screens/tienda_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        elevation: 5,
        title: const Text(
          "La casa del suelo radiante",
          style: TextStyle(
            fontSize: 24, // Ajusta el tamaño del texto según sea necesario
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20), // Reducido para pantallas pequeñas
            Expanded(
              child: GridView.count(
                crossAxisCount: screenWidth > 800 ? 4 : 2, // 4 columnas en pantallas anchas
                mainAxisSpacing: 10, // Reducir espaciado
                crossAxisSpacing: 10,
                childAspectRatio: 0.8, // Más "cuadrado" para 4 columnas
                children: [
                  _buildMenuItem(
                    icon: Icons.add,
                    label: 'Nuevo servicio',
                    color: Colors.blue,
                    iconSize: 30, // Tamaño ajustado
                    onTap: () => _navigateTo(context, const NuevoServicioScreen()),
                  ),
                  _buildMenuItem(
                    icon: Icons.person,
                    label: 'Clientes',
                    color: Colors.green,
                    iconSize: 30,
                    onTap: () => _navigateTo(context, const ClientesScreen()),
                  ),
                  _buildMenuItem(
                    icon: Icons.history,
                    label: 'Historial',
                    color: Colors.orange,
                    iconSize: 30,
                    onTap: () => _navigateTo(context, const HistorialScreen()),
                  ),
                  _buildMenuItem(
                    icon: Icons.shopping_bag,
                    label: 'Tienda',
                    color: Colors.purple,
                    iconSize: 30,
                    onTap: () => _navigateTo(context, TiendaScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    double iconSize = 30, // Parámetro añadido
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3), // Sombra más suave
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30, // Reducido para 4 columnas
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: iconSize, color: color),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0), // Evita desbordamiento
              child: Text(
                label,
                textAlign: TextAlign.center, // Texto centrado
                style: const TextStyle(
                  fontSize: 14, // Reducido para pantallas pequeñas
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await auth.signout(); // Cerrar sesión
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login'); // Redirigir al login
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cerrar sesión: $e")),
        );
      }
    }
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}