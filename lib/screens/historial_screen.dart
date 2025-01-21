import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'servicio_detalle_screen.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({Key? key}) : super(key: key);

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  /// Cada elemento de _historial será un Map con:
  /// {
  ///   'nombre': "...",       // json['cliente']
  ///   'telefono': "...",     // json['telefono']
  ///   'direccion': "...",    // json['direccion']
  ///   'fecha': "...",        // json['fecha']
  ///   'archivo': "...",      // Ruta al archivo .json
  /// }
  List<Map<String, String>> _historial = [];

  /// Al filtrar por fecha o texto, guardamos el resultado en _historialFiltrado
  List<Map<String, String>> _historialFiltrado = [];

  final TextEditingController _busquedaController = TextEditingController();

  /// Fecha actual para filtrar (en tu UI, la ajustas con flechas)
  DateTime _fechaSeleccionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    _listarHistorial();
  }

  /// Recorre la carpeta "Clientes" y sus subcarpetas (fechas) y archivos .json
  /// para armar la lista completa de visitas/servicios
  Future<void> _listarHistorial() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final clientesPath = '${directory.path}/Clientes';
      final clientesDir = Directory(clientesPath);

      if (await clientesDir.exists()) {
        final historial = <Map<String, String>>[];

        // Recorremos cada carpeta de cliente
        for (var clienteDir in clientesDir.listSync().whereType<Directory>()) {
          // Recorremos cada subcarpeta (fechas) dentro de ese cliente
          for (var subdir in clienteDir.listSync().whereType<Directory>()) {
            // Dentro de la subcarpeta, buscamos archivos .json de servicios
            for (var file in subdir.listSync().where((f) => f.path.endsWith('.json'))) {
              final contenido = await File(file.path).readAsString();
              final jsonData = Map<String, dynamic>.from(jsonDecode(contenido));

              // Extraer los campos que nos interesan
              final nombre = jsonData['cliente']?.toString() ?? '';
              final telefono = jsonData['telefono']?.toString() ?? '';
              final direccion = jsonData['direccion']?.toString() ?? 'Sin dirección';
              final fecha = jsonData['fecha']?.toString() ?? subdir.path.split('/').last;

              // Agregamos un map con toda la info necesaria
              historial.add({
                'nombre': nombre,
                'telefono': telefono,
                'direccion': direccion,
                'fecha': fecha,
                'archivo': file.path,
              });
            }
          }
        }

        setState(() {
          _historial = historial;
          // Filtramos por la fecha actual seleccionada
          _filtrarPorFecha();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al listar el historial: $e")),
      );
    }
  }

  /// Filtra las visitas del historial según la fecha seleccionada
  void _filtrarPorFecha() {
    final fechaActualStr = _fechaSeleccionada.toIso8601String().split('T').first;

    // Primero filtramos TODAS las visitas según la fecha
    final visitasPorFecha = _historial.where((visita) {
      // Suponemos que 'fecha' está en formato ISO 8601, por ejemplo "2025-01-20T10:00:00.000"
      // Si no es así, adaptas la lógica.
      final fechaVisita = visita['fecha'] ?? '';
      // Tomamos solo la parte "YYYY-MM-DD"
      final fechaCortaVisita = fechaVisita.split('T').first;
      return fechaCortaVisita == fechaActualStr;
    }).toList();

    // Luego le aplicamos el filtro de texto, si ya hay algo escrito
    final busquedaTexto = _busquedaController.text.trim().toLowerCase();
    if (busquedaTexto.isEmpty) {
      setState(() {
        _historialFiltrado = visitasPorFecha;
      });
    } else {
      // Filtramos además por el texto
      final filtradoTexto = visitasPorFecha.where((visita) {
        final nombre = (visita['nombre'] ?? '').toLowerCase();
        final telefono = (visita['telefono'] ?? '').toLowerCase();
        final direccion = (visita['direccion'] ?? '').toLowerCase();
        return nombre.contains(busquedaTexto)
            || telefono.contains(busquedaTexto)
            || direccion.contains(busquedaTexto);
      }).toList();

      setState(() {
        _historialFiltrado = filtradoTexto;
      });
    }
  }

  /// Filtra por búsqueda (texto). Luego filtra por fecha
  /// para mantener el concepto de "fecha + texto"
  void _filtrarPorBusqueda(String texto) {
    // Actualizamos la lista filtrada basándonos en la fecha actual y el texto
    _filtrarPorFecha();
  }

  /// Cambia la fecha seleccionada en +/-1 día y filtra de nuevo
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
                labelText: "Buscar por nombre, teléfono o dirección",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filtrarPorBusqueda,
            ),
          ),
          // Selector de fecha
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: () => _cambiarFecha(-1),
              ),
              Text(
                fechaStr,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: () => _cambiarFecha(1),
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
                final nombre = visita['nombre'] ?? '';
                final telefono = visita['telefono'] ?? '';
                final direccion = visita['direccion'] ?? '';

                return ListTile(
                  // Muestra el nombre y el teléfono
                  title: Text("$nombre - $telefono"),
                  subtitle: Text(direccion),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ServicioDetalleScreen(archivo: visita['archivo']!),
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
