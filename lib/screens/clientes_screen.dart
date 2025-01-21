import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'visitas_cliente_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({Key? key}) : super(key: key);

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _clientesFiltrados = [];
  final TextEditingController _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listarClientes();
  }

  /// Listar los clientes y cargar datos desde datos_cliente.json en cada carpeta
  /// convirtiendo "direccion" (string) a "direcciones" (lista) si es necesario.
  Future<void> _listarClientes() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final clientesPath = '${directory.path}/Clientes';
      final clientesDir = Directory(clientesPath);

      if (!await clientesDir.exists()) {
        await clientesDir.create(recursive: true);
      }

      final clientes = <Map<String, dynamic>>[];

      // Para cada subcarpeta de "Clientes", buscamos "datos_cliente.json"
      for (var clienteDir in clientesDir.listSync().whereType<Directory>()) {
        final clienteFile = File('${clienteDir.path}/datos_cliente.json');
        if (await clienteFile.exists()) {
          final contenido = await clienteFile.readAsString();
          if (contenido.isEmpty) continue;

          final clienteData = jsonDecode(contenido) as Map<String, dynamic>;

          // Asegurarnos de que "direcciones" sea una lista
          // 1) Si existe 'direccion' de tipo String y NO existe 'direcciones', migrar
          if (clienteData.containsKey('direccion') &&
              clienteData['direccion'] is String &&
              !clienteData.containsKey('direcciones')) {
            final dirUnica = (clienteData['direccion'] as String).trim();
            if (dirUnica.isNotEmpty) {
              clienteData['direcciones'] = [dirUnica];
            } else {
              clienteData['direcciones'] = <String>[];
            }
            // Puedes eliminar la clave 'direccion' o conservarla para compatibilidad
            clienteData.remove('direccion');
          }

          // 2) Si 'direcciones' no existe, la creamos vacía
          if (!clienteData.containsKey('direcciones')) {
            clienteData['direcciones'] = <String>[];
          } else {
            // Convertimos a List<String> por si acaso
            clienteData['direcciones'] = List<String>.from(clienteData['direcciones']);
          }

          clientes.add(clienteData);
        }
      }

      setState(() {
        _clientes = clientes;
        _clientesFiltrados = List.from(clientes);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al listar clientes: $e")),
      );
    }
  }

  /// Filtrar clientes según nombre, teléfono o direcciones (todas unidas como string).
  void _filtrarClientes(String texto) {
    setState(() {
      if (texto.isEmpty) {
        _clientesFiltrados = List.from(_clientes);
      } else {
        final busqueda = texto.toLowerCase();
        _clientesFiltrados = _clientes.where((cliente) {
          final nombre = (cliente['nombre'] ?? '').toLowerCase();
          final telefono = (cliente['telefono'] ?? '').toLowerCase();
          // Unimos todas las direcciones en un string
          final direcciones = (cliente['direcciones'] ?? <String>[]) as List<String>;
          final direccionesStr = direcciones.join(' ').toLowerCase();

          return nombre.contains(busqueda)
              || telefono.contains(busqueda)
              || direccionesStr.contains(busqueda);
        }).toList();
      }
    });
  }

  /// Editar datos de un cliente con múltiples direcciones
  Future<void> _editarCliente(Map<String, dynamic> cliente) async {
    final nombreController = TextEditingController(text: cliente['nombre']);
    final telefonoController = TextEditingController(text: cliente['telefono']);
    final emailController = TextEditingController(text: cliente['email']);

    // Unimos las direcciones en un campo multilinea
    final direcciones = (cliente['direcciones'] ?? <String>[]) as List<String>;
    final direccionesController = TextEditingController(
      text: direcciones.join('\n'),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Editar Cliente"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: "Nombre"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: telefonoController,
                  decoration: const InputDecoration(labelText: "Teléfono"),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                // Múltiples direcciones en multilinea
                TextField(
                  controller: direccionesController,
                  decoration: const InputDecoration(
                    labelText: "Direcciones (una por línea)",
                  ),
                  maxLines: 4, // Ajusta según lo necesites
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                // Actualiza el Map local con los nuevos datos
                final nuevoNombre = nombreController.text.trim();
                final nuevoTelefono = telefonoController.text.trim();
                final nuevoEmail = emailController.text.trim();

                // Separamos por saltos de línea para obtener la lista de direcciones
                final nuevasDirecciones = direccionesController.text
                    .split('\n')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                cliente['nombre'] = nuevoNombre;
                cliente['telefono'] = nuevoTelefono;
                cliente['email'] = nuevoEmail;
                cliente['direcciones'] = nuevasDirecciones;

                // Guardar en disco
                final directory = await getApplicationDocumentsDirectory();
                final clientePath = '${directory.path}/Clientes/$nuevoTelefono';
                final clienteDir = Directory(clientePath);

                // Crear carpeta si no existe (p.ej. si se cambió el teléfono)
                if (!await clienteDir.exists()) {
                  await clienteDir.create(recursive: true);
                }

                final clienteFile = File('$clientePath/datos_cliente.json');
                await clienteFile.writeAsString(jsonEncode(cliente));

                setState(() {
                  _listarClientes();
                });
                Navigator.of(context).pop();
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  /// Eliminar cliente
  Future<void> _eliminarCliente(String telefono) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Cliente"),
        content: const Text("¿Estás seguro de que quieres eliminar este cliente?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final directory = await getApplicationDocumentsDirectory();
      final clientePath = '${directory.path}/Clientes/$telefono';
      final clienteDir = Directory(clientePath);

      if (await clienteDir.exists()) {
        await clienteDir.delete(recursive: true);
      }

      setState(() {
        _listarClientes();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Clientes",
          style: TextStyle(color: Colors.white), // Título en blanco
        ),
        centerTitle: true, // Centrar el título
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(
          color: Colors.white, // Flecha "back" en blanco
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
                labelText: "Buscar por nombre, teléfono o direcciones",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filtrarClientes,
            ),
          ),
          // Lista de clientes
          Expanded(
            child: _clientesFiltrados.isEmpty
                ? const Center(child: Text("No hay clientes registrados."))
                : ListView.builder(
              itemCount: _clientesFiltrados.length,
              itemBuilder: (context, index) {
                final cliente = _clientesFiltrados[index];
                final nombre = cliente['nombre'] ?? 'Sin Nombre';
                final telefono = cliente['telefono'] ?? 'Sin Teléfono';
                final direcciones = (cliente['direcciones'] ?? []) as List<String>;

                // Unir las direcciones con salto de línea o coma
                final direccionesStr = direcciones.isNotEmpty
                    ? direcciones.join(', ')
                    : 'Sin direcciones';

                return ListTile(
                  title: Text(nombre),
                  subtitle: Text("Tel: $telefono\nDir: $direccionesStr"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editarCliente(cliente),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _eliminarCliente(telefono),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navegar a la pantalla de visitas del cliente
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VisitasClienteScreen(
                          telefono: telefono,
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
