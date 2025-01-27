import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Para Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Para obtener el usuario autenticado
import 'servicio_detalle_screen.dart'; // Importa la pantalla de detalles del servicio

class VisitasClienteScreen extends StatefulWidget {
  final String telefono; // Teléfono del cliente

  const VisitasClienteScreen({Key? key, required this.telefono}) : super(key: key);

  @override
  State<VisitasClienteScreen> createState() => _VisitasClienteScreenState();
}

class _VisitasClienteScreenState extends State<VisitasClienteScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Instancia de Firestore
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instancia de FirebaseAuth
  List<Map<String, dynamic>> _servicios = []; // Lista de servicios del cliente

  @override
  void initState() {
    super.initState();
    _cargarServicios(); // Cargar servicios al iniciar la pantalla
  }

  /// Cargar servicios desde Firestore, filtrados por el teléfono del cliente
  Future<void> _cargarServicios() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Usuario no autenticado")),
          );
        }
        return;
      }

      final userId = user.uid;
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('servicios') // Colección de servicios del usuario
          .where('telefono', isEqualTo: widget.telefono) // Filtrar por teléfono del cliente
          .get();

      setState(() {
        _servicios = querySnapshot.docs.map((doc) {
          return {
            'id': doc.id, // ID del servicio
            ...doc.data() as Map<String, dynamic>, // Datos del servicio
          };
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar servicios: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Servicios del Cliente"),
      ),
      body: _servicios.isEmpty
          ? const Center(child: Text("No hay servicios registrados."))
          : ListView.builder(
        itemCount: _servicios.length,
        itemBuilder: (context, index) {
          final servicio = _servicios[index];
          final fecha = servicio['fecha'] ?? 'Sin Fecha';
          final descripcion = servicio['descripcion'] ?? 'Sin Descripción';

          return ListTile(
            title: Text("Servicio - $fecha"),
            subtitle: Text(descripcion),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              // Navegar a la pantalla de detalles del servicio
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServicioDetalleScreen(
                    visita: servicio, // Pasar los datos del servicio
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}