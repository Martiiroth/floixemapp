import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Para Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Para obtener el usuario autenticado
import 'visitas_cliente_screen.dart'; // Importa la pantalla de visitas

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({Key? key}) : super(key: key);

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Instancia de Firestore
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instancia de FirebaseAuth
  final TextEditingController _busquedaController = TextEditingController();
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _clientesFiltrados = [];

  @override
  void initState() {
    super.initState();
    _cargarClientes(); // Cargar clientes al iniciar la pantalla
  }

  /// Cargar clientes desde Firestore
  Future<void> _cargarClientes() async {
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
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('clientes')
          .get();

      setState(() {
        _clientes = querySnapshot.docs.map((doc) {
          return {
            'id': doc.id, // ID del documento
            ...doc.data() as Map<String, dynamic>, // Datos del cliente
          };
        }).toList();
        _clientesFiltrados = List.from(_clientes); // Inicialmente, mostrar todos los clientes
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar clientes: $e")),
        );
      }
    }
  }

  /// Filtrar clientes por nombre, teléfono o direcciones
  void _filtrarClientes(String texto) {
    setState(() {
      if (texto.isEmpty) {
        _clientesFiltrados = List.from(_clientes); // Mostrar todos los clientes si no hay texto
      } else {
        final busqueda = texto.toLowerCase();
        _clientesFiltrados = _clientes.where((cliente) {
          final nombre = (cliente['nombre'] ?? '').toLowerCase();
          final telefono = (cliente['telefono'] ?? '').toLowerCase();
          final direcciones = (cliente['direcciones'] ?? <dynamic>[]).cast<String>();
          final direccionesStr = direcciones.join(' ').toLowerCase();

          return nombre.contains(busqueda) ||
              telefono.contains(busqueda) ||
              direccionesStr.contains(busqueda);
        }).toList();
      }
    });
  }

  /// Editar un cliente
  Future<void> _editarCliente(Map<String, dynamic> cliente) async {
    final nombreController = TextEditingController(text: cliente['nombre']);
    final telefonoController = TextEditingController(text: cliente['telefono']);
    final emailController = TextEditingController(text: cliente['email']);

    // Unir las direcciones en un campo multilínea
    final direcciones = (cliente['direcciones'] ?? <dynamic>[]).cast<String>();
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
                // Múltiples direcciones en multilínea
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
                // Actualizar el cliente en Firestore
                final nuevoNombre = nombreController.text.trim();
                final nuevoTelefono = telefonoController.text.trim();
                final nuevoEmail = emailController.text.trim();

                // Separar por saltos de línea para obtener la lista de direcciones
                final nuevasDirecciones = direccionesController.text
                    .split('\n')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                final user = _auth.currentUser;
                if (user != null) {
                  final userId = user.uid;
                  await _firestore
                      .collection('users')
                      .doc(userId)
                      .collection('clientes')
                      .doc(cliente['id'])
                      .update({
                    'nombre': nuevoNombre,
                    'telefono': nuevoTelefono,
                    'email': nuevoEmail,
                    'direcciones': nuevasDirecciones,
                  });

                  setState(() {
                    _cargarClientes(); // Recargar la lista de clientes después de editar
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  /// Eliminar un cliente
  Future<void> _eliminarCliente(String id) async {
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
      final user = _auth.currentUser;
      if (user != null) {
        final userId = user.uid;
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('clientes')
            .doc(id)
            .delete();
        setState(() {
          _cargarClientes(); // Recargar la lista de clientes después de eliminar
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarClientes, // Botón para recargar clientes
          ),
        ],
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
                final direcciones = (cliente['direcciones'] ?? <dynamic>[]).cast<String>();
                final direccionesStr = direcciones.isNotEmpty
                    ? direcciones.join(', ')
                    : 'Sin direcciones';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
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
                          onPressed: () => _eliminarCliente(cliente['id']),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Navegar a la pantalla de visitas del cliente
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VisitasClienteScreen(
                            telefono: telefono, // Pasar el teléfono del cliente
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}