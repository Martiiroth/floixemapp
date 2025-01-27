import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Para Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Para obtener el usuario autenticado
import 'servicio_detalle_screen.dart'; // Pantalla de detalles del servicio

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({Key? key}) : super(key: key);

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Instancia de Firestore
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instancia de FirebaseAuth
  final TextEditingController _busquedaController = TextEditingController();
  List<Map<String, dynamic>> _historial = []; // Lista completa de visitas
  List<Map<String, dynamic>> _historialFiltrado = []; // Lista filtrada por fecha y texto
  DateTime _fechaSeleccionada = DateTime.now(); // Fecha actual para filtrar

  @override
  void initState() {
    super.initState();
    _cargarHistorial(); // Cargar historial al iniciar la pantalla
  }

  /// Cargar el historial de visitas desde Firestore
  Future<void> _cargarHistorial() async {
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
          .get();

      setState(() {
        _historial = querySnapshot.docs.map((doc) {
          return {
            'id': doc.id, // ID del documento
            ...doc.data() as Map<String, dynamic>, // Datos de la visita
          };
        }).toList();
        _filtrarPorFecha(); // Aplicar filtro inicial por fecha
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar el historial: $e")),
        );
      }
    }
  }

  /// Filtrar las visitas por la fecha seleccionada
  void _filtrarPorFecha() {
    final fechaActualStr = _fechaSeleccionada.toIso8601String().split('T').first;

    // Filtramos las visitas por fecha
    final visitasPorFecha = _historial.where((visita) {
      final fechaVisita = visita['fecha'] ?? '';
      final fechaCortaVisita = fechaVisita.split('T').first;
      return fechaCortaVisita == fechaActualStr;
    }).toList();

    // Aplicar filtro de texto si hay algo escrito
    final busquedaTexto = _busquedaController.text.trim().toLowerCase();
    if (busquedaTexto.isEmpty) {
      setState(() {
        _historialFiltrado = visitasPorFecha;
      });
    } else {
      // Filtramos además por el texto
      final filtradoTexto = visitasPorFecha.where((visita) {
        final telefono = (visita['telefono'] ?? '').toLowerCase();
        final direccion = (visita['direccion'] ?? '').toLowerCase();
        return telefono.contains(busquedaTexto) ||
            direccion.contains(busquedaTexto);
      }).toList();

      setState(() {
        _historialFiltrado = filtradoTexto;
      });
    }
  }

  /// Cambiar la fecha seleccionada en +/-1 día y filtrar de nuevo
  void _cambiarFecha(int dias) {
    setState(() {
      _fechaSeleccionada = _fechaSeleccionada.add(Duration(days: dias));
    });
    _filtrarPorFecha();
  }

  @override
  Widget build(BuildContext context) {
    final fechaStr = _fechaSeleccionada.toIso8601String().split('T').first;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Historial",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _busquedaController,
              decoration: const InputDecoration(
                labelText: "Buscar por teléfono o dirección",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (texto) => _filtrarPorFecha(), // Filtrar al cambiar el texto
            ),
          ),
          // Selector de fecha
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: () => _cambiarFecha(-1), // Retroceder un día
              ),
              Text(
                fechaStr,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: () => _cambiarFecha(1), // Avanzar un día
              ),
            ],
          ),
          // Lista de visitas
          Expanded(
            child: _historialFiltrado.isEmpty
                ? const Center(child: Text("No hay visitas para esta fecha."))
                : ListView.builder(
              itemCount: _historialFiltrado.length,
              itemBuilder: (context, index) {
                final visita = _historialFiltrado[index];
                final telefono = visita['telefono'] ?? 'Sin Teléfono';
                final direccion = visita['direccion'] ?? 'Sin Dirección';

                return ListTile(
                  title: Text(telefono), // Solo muestra el teléfono
                  subtitle: Text(direccion), // Muestra la dirección
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    // Navegar a la pantalla de detalles del servicio
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServicioDetalleScreen(
                          visita: visita, // Pasar los datos de la visita
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}