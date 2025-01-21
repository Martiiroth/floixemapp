import 'package:flutter/material.dart';

// IMPORTS de tus clases/pantallas
import 'package:floixemapp/auth/auth_service.dart';
import 'package:floixemapp/auth/login_screen.dart';
import 'package:floixemapp/screens/nuevo_servicio_screen.dart';
import 'package:floixemapp/screens/clientes_screen.dart';
import 'package:floixemapp/screens/historial_screen.dart';
import 'package:floixemapp/screens/tienda_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _auth = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "HOME",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        elevation: 5,
        actions: [
          IconButton(
            onPressed: () async {
              // Acción de cerrar sesión
              await _auth.signout();
              // Navegación a la pantalla de Login
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Espacio superior
            const SizedBox(height: 60),
            // Título FLOIXEM
            const Text(
              "FLOIXEM",
              style: TextStyle(
                fontSize: 70,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 40),
            // Cuadrícula de menús
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  // 1) Nuevo servicio
                  _buildMenuItem(
                    icon: Icons.add,
                    label: 'Nuevo servicio',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NuevoServicioScreen(),
                        ),
                      );
                    },
                  ),
                  // 2) Clientes
                  _buildMenuItem(
                    icon: Icons.person,
                    label: 'Clientes',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientesScreen(),
                        ),
                      );
                    },
                  ),
                  // 3) Historial
                  _buildMenuItem(
                    icon: Icons.history,
                    label: 'Historial',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HistorialScreen(),
                        ),
                      );
                    },
                  ),
                  // 4) Tienda
                  _buildMenuItem(
                    icon: Icons.shopping_bag,
                    label: 'Tienda',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TiendaScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Item genérico para la cuadrícula
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícono circular
            CircleAvatar(
              radius: 40,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            // Etiqueta del ítem
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
