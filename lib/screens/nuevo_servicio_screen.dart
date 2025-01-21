import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class NuevoServicioScreen extends StatefulWidget {
  const NuevoServicioScreen({Key? key}) : super(key: key);

  @override
  State<NuevoServicioScreen> createState() => _NuevoServicioScreenState();
}

class _NuevoServicioScreenState extends State<NuevoServicioScreen> {
  // Controladores de texto principales
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Se usará para guardar direcciones existentes y seleccionar una
  List<String> _direccionesCliente = [];
  String? _direccionSeleccionada;

  // Para agregar una dirección nueva en tiempo real
  final TextEditingController _nuevaDireccionController = TextEditingController();

  // Controladores para otros campos del servicio
  final TextEditingController _phController = TextEditingController();
  final TextEditingController _conductividadController = TextEditingController();
  final TextEditingController _concentracionController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  // Manejo de imágenes
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();

  // Map para almacenar datos de clientes (teléfono -> datos del cliente)
  final Map<String, dynamic> _clientesData = {};

  // Dropdown de tipo de servicio
  String _tipoServicio = "Nueva instalación";
  final List<String> _opcionesServicio = [
    "Nueva instalación",
    "Primera visita",
    "Visita mantenimiento",
    "Comprobación",
  ];

  /// Lista de productos y sus cantidades
  final List<Map<String, dynamic>> _productos = [
    {'nombre': 'Floixem B', 'cantidad': 0},
    {'nombre': 'Floixem C', 'cantidad': 0},
    {'nombre': 'Floixem I', 'cantidad': 0},
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosClientes();
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _nuevaDireccionController.dispose();
    _phController.dispose();
    _conductividadController.dispose();
    _concentracionController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  /// Cargar datos de clientes desde el almacenamiento local.
  /// En este ejemplo, cada cliente está en `Clientes/<telefono>/datos_cliente.json`.
  Future<void> _cargarDatosClientes() async {
    final directory = await getApplicationDocumentsDirectory();
    final clientesDir = Directory('${directory.path}/Clientes');

    // Crea la carpeta base si no existe (evita errores en .listSync())
    if (!(await clientesDir.exists())) {
      await clientesDir.create(recursive: true);
    }

    // Limpia el map de clientes por si recargas varias veces.
    _clientesData.clear();

    // Busca en la carpeta de clientes
    for (var entry in clientesDir.listSync()) {
      if (entry is Directory) {
        final clienteFile = File('${entry.path}/datos_cliente.json');
        if (await clienteFile.exists()) {
          final clienteData = jsonDecode(await clienteFile.readAsString());
          // Guarda en el map, usando el teléfono como key.
          final tel = clienteData['telefono'] as String;
          _clientesData[tel] = {
            'nombre': clienteData['nombre'] ?? '',
            'telefono': tel,
            'email': clienteData['email'] ?? '',
            // Convertimos direcciones a lista, si existe.
            'direcciones': clienteData['direcciones'] != null
                ? List<String>.from(clienteData['direcciones'])
                : <String>[],
          };
        }
      }
    }
    setState(() {});
  }

  /// Autocompleta los datos del cliente, en base al teléfono que se introduzca
  void _autocompletarDatosPorTelefono(String telefono) {
    final cliente = _clientesData[telefono];
    if (cliente != null) {
      setState(() {
        _clienteController.text = cliente['nombre'] ?? '';
        _emailController.text = cliente['email'] ?? '';
        _direccionesCliente = List<String>.from(cliente['direcciones'] ?? []);

        // Seleccionamos la primera dirección de la lista (si hay)
        _direccionSeleccionada = _direccionesCliente.isNotEmpty
            ? _direccionesCliente.first
            : null;
      });
    } else {
      // No existe el cliente => Limpiamos campos
      setState(() {
        _clienteController.clear();
        _emailController.clear();
        _direccionesCliente = [];
        _direccionSeleccionada = null;
      });
    }
  }

  /// Permite agregar o unir una nueva dirección a la lista
  void _agregarNuevaDireccion() {
    final nuevaDir = _nuevaDireccionController.text.trim();
    if (nuevaDir.isNotEmpty && !_direccionesCliente.contains(nuevaDir)) {
      setState(() {
        _direccionesCliente.add(nuevaDir);
        _direccionSeleccionada = nuevaDir;
      });
    }
    _nuevaDireccionController.clear();
  }

  /// Seleccionar imágenes de la galería
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _images.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al seleccionar imagen: $e")),
      );
    }
  }

  /// Guardar servicio y actualizar la información del cliente
  Future<void> _guardarServicio() async {
    try {
      // Validaciones mínimas
      final tel = _telefonoController.text.trim();
      if (tel.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor, ingresa el teléfono.")),
        );
        return;
      }

      // Toma la dirección seleccionada (o la última que se agregó) como "dirección principal"
      // Dependerá de tu lógica si quieres usar "direccionSeleccionada" o "nuevaDireccionController".
      // En este ejemplo, no forzamos nada, solo demostramos cómo guardarlo.
      // Se asume que si hay _direccionesCliente y _direccionSeleccionada, se usará esa.
      // De lo contrario, se podría usar un campo distinto.
      final directory = await getApplicationDocumentsDirectory();
      final clientePath = '${directory.path}/Clientes/$tel';
      final clienteDir = Directory(clientePath);

      // Crea la carpeta del cliente si no existe
      if (!await clienteDir.exists()) {
        await clienteDir.create(recursive: true);
      }

      // Lee o prepara el contenido previo del cliente (para no perder direcciones)
      final clienteFile = File('${clienteDir.path}/datos_cliente.json');
      Map<String, dynamic> clienteData = {};
      if (await clienteFile.exists()) {
        final contenido = await clienteFile.readAsString();
        if (contenido.isNotEmpty) {
          clienteData = jsonDecode(contenido);
        }
      }

      // Maneja la lista de direcciones
      List<String> direccionesActuales = [];
      if (clienteData.containsKey('direcciones')) {
        direccionesActuales = List<String>.from(clienteData['direcciones']);
      }

      // Une nuestras direcciones en memoria con las del JSON
      for (var dir in _direccionesCliente) {
        if (!direccionesActuales.contains(dir)) {
          direccionesActuales.add(dir);
        }
      }

      // Actualizamos los campos del cliente
      clienteData['nombre'] = _clienteController.text;
      clienteData['telefono'] = tel;
      clienteData['email'] = _emailController.text;
      clienteData['direcciones'] = direccionesActuales;

      // Sobrescribe (o crea) datos_cliente.json
      await clienteFile.writeAsString(jsonEncode(clienteData));

      // Ahora creamos la carpeta por fecha (por ejemplo) para los servicios
      final fechaActual = DateTime.now();
      final fechaSubcarpeta =
          '${fechaActual.year}-${fechaActual.month.toString().padLeft(2, '0')}-${fechaActual.day.toString().padLeft(2, '0')}';
      final fechaPath = '$clientePath/$fechaSubcarpeta';
      final fechaDir = Directory(fechaPath);
      if (!await fechaDir.exists()) {
        await fechaDir.create(recursive: true);
      }

      // Creamos un nombre único para este servicio
      final servicioId = DateTime.now().millisecondsSinceEpoch.toString();
      final servicioPath = '$fechaPath/Servicio_$servicioId.json';

      // Copiamos las imágenes seleccionadas a la carpeta de fecha
      final imagenesPaths = <String>[];
      for (var image in _images) {
        final imageName = 'imagen_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final imagePath = '$fechaPath/$imageName';
        await image.copy(imagePath);
        imagenesPaths.add(imagePath);
      }

      // Creamos el Map con la información del servicio
      final servicioData = {
        'cliente': _clienteController.text.trim(),
        'telefono': tel,
        'email': _emailController.text.trim(),
        // Si quieres que "direccion" sea la que está seleccionada,
        // la puedes incluir así:
        'direccion': _direccionSeleccionada ?? '',
        'tipoServicio': _tipoServicio,
        'ph': _phController.text.trim(),
        'conductividad': _conductividadController.text.trim(),
        'concentracion': _concentracionController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'productos': _productos,
        'fecha': fechaActual.toIso8601String(),
        'imagenes': imagenesPaths,
      };

      // Guardamos el servicio
      final servicioFile = File(servicioPath);
      await servicioFile.writeAsString(jsonEncode(servicioData));

      // Notifica al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Servicio guardado correctamente.")),
      );

      // Limpieza de campos
      setState(() {
        _clienteController.clear();
        _telefonoController.clear();
        _emailController.clear();
        _direccionesCliente = [];
        _direccionSeleccionada = null;
        _nuevaDireccionController.clear();
        _phController.clear();
        _conductividadController.clear();
        _concentracionController.clear();
        _descripcionController.clear();
        _images.clear();
        _tipoServicio = "Nueva instalación";
        for (var producto in _productos) {
          producto['cantidad'] = 0;
        }
      });

      // Recarga datos de clientes en memoria, por si acabas de crear uno
      await _cargarDatosClientes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar el servicio: $e")),
      );
    }
  }

  /// Actualizar la cantidad de un producto
  void _actualizarCantidad(String nombreProducto, int nuevaCantidad) {
    setState(() {
      final producto =
      _productos.firstWhere((p) => p['nombre'] == nombreProducto);
      producto['cantidad'] = nuevaCantidad;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Nuevo Servicio",
          style: TextStyle(color: Colors.white), // Título en blanco
        ),
        centerTitle: true, // Centrar el título
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(
          color: Colors.white, // Flecha "back" en blanco
        ),
      ),


      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Información del Cliente",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Teléfono
            TextField(
              controller: _telefonoController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Teléfono",
                border: OutlineInputBorder(),
              ),
              // Aquí, si quieres que autocomplete solo al finalizar, usa onSubmitted
              // o un botón de "Buscar". Con onChanged, lo hace en cada pulsación:
              onChanged: _autocompletarDatosPorTelefono,
            ),
            const SizedBox(height: 16),

            // Nombre
            TextField(
              controller: _clienteController,
              decoration: const InputDecoration(
                labelText: "Nombre del Cliente",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Email
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown para direcciones existentes
            if (_direccionesCliente.isNotEmpty)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Dirección Existente",
                  border: OutlineInputBorder(),
                ),
                value: _direccionSeleccionada,
                items: _direccionesCliente.map((dir) {
                  return DropdownMenuItem<String>(
                    value: dir,
                    child: Text(dir),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _direccionSeleccionada = value;
                  });
                },
              ),
            if (_direccionesCliente.isNotEmpty) const SizedBox(height: 16),

            // Campo para ingresar nueva dirección
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nuevaDireccionController,
                    decoration: const InputDecoration(
                      labelText: 'Nueva Dirección',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _agregarNuevaDireccion,
                  icon: const Icon(Icons.add),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Detalles del Servicio
            const Text(
              "Detalles del Servicio",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Tipo de servicio
            DropdownButtonFormField<String>(
              value: _tipoServicio,
              items: _opcionesServicio.map((opcion) {
                return DropdownMenuItem<String>(
                  value: opcion,
                  child: Text(opcion),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _tipoServicio = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: "Tipo de Servicio",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // pH
            TextField(
              controller: _phController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "pH",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Conductividad
            TextField(
              controller: _conductividadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Conductividad",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Concentración
            TextField(
              controller: _concentracionController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Concentración",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Descripción
            TextField(
              controller: _descripcionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Descripción del Servicio",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Productos utilizados
            const Text(
              "Productos Utilizados",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Column(
              children: _productos.map((producto) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(producto['nombre'], style: const TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (producto['cantidad'] > 0) {
                              _actualizarCantidad(
                                producto['nombre'],
                                producto['cantidad'] - 1,
                              );
                            }
                          },
                        ),
                        Text('${producto['cantidad']}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            _actualizarCantidad(
                              producto['nombre'],
                              producto['cantidad'] + 1,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Imágenes del Servicio
            const Text(
              "Imágenes del Servicio",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _images
                    .map((image) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Image.file(image, width: 100, height: 100),
                ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text("Añadir Imagen"),
            ),
            const SizedBox(height: 24),

            // Botón para guardar
            Center(
              child: ElevatedButton(
                onPressed: _guardarServicio,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Guardar Servicio"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
