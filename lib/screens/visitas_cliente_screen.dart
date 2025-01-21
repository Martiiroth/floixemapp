import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'servicio_detalle_screen.dart';

class VisitasClienteScreen extends StatefulWidget {
  final String telefono;

  const VisitasClienteScreen({Key? key, required this.telefono})
      : super(key: key);

  @override
  State<VisitasClienteScreen> createState() => _VisitasClienteScreenState();
}

class _VisitasClienteScreenState extends State<VisitasClienteScreen> {
  List<Map<String, String>> _visitas = [];

  @override
  void initState() {
    super.initState();
    _listarVisitas();
  }

  /// Listar las visitas asociadas a un cliente, basándose en su teléfono
  Future<void> _listarVisitas() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final clientePath = '${directory.path}/Clientes/${widget.telefono}';
      final clienteDir = Directory(clientePath);

      if (await clienteDir.exists()) {
        final visitas = <Map<String, String>>[];

        // Buscamos subcarpetas (fechas) y archivos .json de servicios
        for (var subdir in clienteDir.listSync().whereType<Directory>()) {
          for (var file
          in subdir.listSync().where((f) => f.path.endsWith('.json'))) {
            final contenido = await File(file.path).readAsString();
            final jsonData = Map<String, dynamic>.from(jsonDecode(contenido));

            final fecha = jsonData['fecha'] ?? subdir.path.split('/').last;
            final direccion = jsonData['direccion'] ?? "Sin dirección";

            visitas.add({
              'fecha': fecha.toString(),
              'direccion': direccion,
              'archivo': file.path,
            });
          }
        }

        // Ordenar las visitas por fecha descendente (opcional)
        // Aquí asumimos que 'fecha' es un string en ISO8601. Si no, ajusta la lógica.
        visitas.sort((a, b) => b['fecha']!.compareTo(a['fecha']!));

        setState(() {
          _visitas = visitas;
        });
      } else {
        // Si no existe la carpeta, es que no hay visitas
        setState(() {
          _visitas = [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al listar visitas: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = "Visitas de ${widget.telefono}";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Visitas",
          style: TextStyle(color: Colors.white), // Título en blanco
        ),
        centerTitle: true, // Centrar el título
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(
          color: Colors.white, // Flecha "back" en blanco
        ),
      ),

      body: _visitas.isEmpty
          ? const Center(child: Text("No hay visitas registradas."))
          : ListView.builder(
        itemCount: _visitas.length,
        itemBuilder: (context, index) {
          final visita = _visitas[index];
          final fecha = visita['fecha'] ?? '';
          final direccion = visita['direccion'] ?? '';

          return ListTile(
            title: Text("Visita - $fecha"),
            subtitle: Text(direccion),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              // Abrir el detalle de ese servicio en particular
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServicioDetalleScreen(
                    archivo: visita['archivo']!,
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
