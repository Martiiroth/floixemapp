import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:floixemapp/auth/auth_service.dart';

class NuevoServicioScreen extends StatefulWidget {
  const NuevoServicioScreen({Key? key}) : super(key: key);

  @override
  State<NuevoServicioScreen> createState() => _NuevoServicioScreenState();
}

class _NuevoServicioScreenState extends State<NuevoServicioScreen> {
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nuevaDireccionController = TextEditingController();
  final TextEditingController _phController = TextEditingController();
  final TextEditingController _conductividadController = TextEditingController();
  final TextEditingController _concentracionController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _defectosController = TextEditingController();

  List<String> _direccionesCliente = [];
  String? _direccionSeleccionada;
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();

  File? _phImage;
  File? _conductividadImage;
  File? _concentracionImage;

  String _tipoServicio = "Nueva instalación";
  final List<String> _opcionesServicio = [
    "Nueva instalación",
    "Primera visita",
    "Visita mantenimiento",
    "Comprobación",
  ];

  String? _proximaVisita;
  final List<String> _opcionesProximaVisita = [
    "6 meses",
    "1 año",
    "2 años",
  ];

  final List<Map<String, dynamic>> _productos = [
    {'nombre': 'Floixem B', 'cantidad': 0},
    {'nombre': 'Floixem C', 'cantidad': 0},
    {'nombre': 'Floixem I', 'cantidad': 0},
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _telefonoController.addListener(_buscarClientePorTelefono);
  }

  @override
  void dispose() {
    _telefonoController.removeListener(_buscarClientePorTelefono);
    _telefonoController.dispose();
    _defectosController.dispose();
    super.dispose();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
  }

  Future<void> _buscarClientePorTelefono() async {
    final tel = _telefonoController.text.trim();
    if (tel.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final userId = user.uid;

    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('clientes')
        .doc(tel)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _clienteController.text = data['nombre'] ?? '';
        _emailController.text = data['email'] ?? '';
        _direccionesCliente = List<String>.from(data['direcciones'] ?? []);
        _direccionSeleccionada = _direccionesCliente.isNotEmpty ? _direccionesCliente.first : null;
      });
    }
  }

  Future<void> _pickImage(ImageSource source, String type) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          if (type == 'ph') {
            _phImage = File(pickedFile.path);
          } else if (type == 'conductividad') {
            _conductividadImage = File(pickedFile.path);
          } else if (type == 'concentracion') {
            _concentracionImage = File(pickedFile.path);
          } else {
            _images.add(File(pickedFile.path));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al seleccionar imagen: $e")),
        );
      }
    }
  }

  Future<void> _guardarServicio() async {
    try {
      final tel = _telefonoController.text.trim();
      if (tel.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Por favor, ingresa el teléfono.")),
          );
        }
        return;
      }

      final List<String> imagenesUrls = [];
      for (var image in _images) {
        final url = await _authService.uploadFileToDrive(image);
        if (url != null) {
          imagenesUrls.add(url);
        }
      }

      final String? phImageUrl = _phImage != null ? await _authService.uploadFileToDrive(_phImage!) : null;
      final String? conductividadImageUrl = _conductividadImage != null ? await _authService.uploadFileToDrive(_conductividadImage!) : null;
      final String? concentracionImageUrl = _concentracionImage != null ? await _authService.uploadFileToDrive(_concentracionImage!) : null;

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

      final clienteData = {
        'nombre': _clienteController.text.trim(),
        'telefono': tel,
        'email': _emailController.text.trim(),
        'direcciones': _direccionesCliente,
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('clientes')
          .doc(tel)
          .set(clienteData);

      final servicioData = {
        'cliente': _clienteController.text.trim(),
        'telefono': tel,
        'email': _emailController.text.trim(),
        'direccion': _direccionSeleccionada ?? '',
        'tipoServicio': _tipoServicio,
        'ph': _phController.text.trim(),
        'phImage': phImageUrl,
        'conductividad': _conductividadController.text.trim(),
        'conductividadImage': conductividadImageUrl,
        'concentracion': _concentracionController.text.trim(),
        'concentracionImage': concentracionImageUrl,
        'descripcion': _descripcionController.text.trim(),
        'defectos': _defectosController.text.trim(),
        'productos': _productos,
        'fecha': DateTime.now().toIso8601String(),
        'imagenes': imagenesUrls,
        'proximaVisita': _proximaVisita,
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('servicios')
          .add(servicioData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Servicio guardado correctamente.")),
        );
      }

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
        _defectosController.clear();
        _images.clear();
        _phImage = null;
        _conductividadImage = null;
        _concentracionImage = null;
        _tipoServicio = "Nueva instalación";
        _proximaVisita = null;
        for (var producto in _productos) {
          producto['cantidad'] = 0;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar el servicio: $e")),
        );
      }
    }
  }

  void _actualizarCantidad(String nombreProducto, int nuevaCantidad) {
    setState(() {
      final producto = _productos.firstWhere((p) => p['nombre'] == nombreProducto);
      producto['cantidad'] = nuevaCantidad;
    });
  }

  Widget _buildImagePickerField({
    required String label,
    required TextEditingController controller,
    required File? image,
    required Function(ImageSource source, String type) onPickImage,
    required String type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => onPickImage(ImageSource.gallery, type),
              icon: const Icon(Icons.camera_alt, color: Colors.deepOrange),
            ),
          ],
        ),
        if (image != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                image,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Nuevo Servicio",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Información del Cliente",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _telefonoController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Teléfono *",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _clienteController,
              decoration: InputDecoration(
                labelText: "Nombre del Cliente *",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            if (_direccionesCliente.isNotEmpty) ...[
              const Text(
                "Direcciones Existentes",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _direccionSeleccionada,
                  onChanged: (String? newValue) {
                    setState(() {
                      _direccionSeleccionada = newValue;
                    });
                  },
                  items: _direccionesCliente.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nuevaDireccionController,
                    decoration: InputDecoration(
                      labelText: 'Nueva Dirección',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final nuevaDir = _nuevaDireccionController.text.trim();
                    if (nuevaDir.isNotEmpty && !_direccionesCliente.contains(nuevaDir)) {
                      setState(() {
                        _direccionesCliente.add(nuevaDir);
                        _direccionSeleccionada = nuevaDir;
                      });
                    }
                    _nuevaDireccionController.clear();
                  },
                  icon: const Icon(Icons.add, color: Colors.deepOrange),
                )
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Detalles del Servicio",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
            const SizedBox(height: 16),
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
              decoration: InputDecoration(
                labelText: "Tipo de Servicio *",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            _buildImagePickerField(
              label: "pH",
              controller: _phController,
              image: _phImage,
              onPickImage: _pickImage,
              type: 'ph',
            ),
            _buildImagePickerField(
              label: "Conductividad",
              controller: _conductividadController,
              image: _conductividadImage,
              onPickImage: _pickImage,
              type: 'conductividad',
            ),
            _buildImagePickerField(
              label: "Concentración",
              controller: _concentracionController,
              image: _concentracionImage,
              onPickImage: _pickImage,
              type: 'concentracion',
            ),
            const SizedBox(height: 16),
            const Text(
              "Próxima Visita",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _proximaVisita,
              items: _opcionesProximaVisita.map((opcion) {
                return DropdownMenuItem<String>(
                  value: opcion,
                  child: Text(opcion),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _proximaVisita = value;
                });
              },
              decoration: InputDecoration(
                labelText: "Seleccione la próxima visita",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descripcionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Descripción del Servicio *",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _defectosController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Defectos",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Productos Utilizados",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
            const SizedBox(height: 8),
            Column(
              children: _productos.map((producto) {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(producto['nombre'], style: const TextStyle(fontSize: 16)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.deepOrange),
                              onPressed: () {
                                if (producto['cantidad'] > 0) {
                                  _actualizarCantidad(
                                    producto['nombre'],
                                    producto['cantidad'] - 1,
                                  );
                                }
                              },
                            ),
                            Text('${producto['cantidad']}', style: const TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.deepOrange),
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
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              "Imágenes del Servicio",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _images
                    .map((image) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(image, width: 100, height: 100, fit: BoxFit.cover),
                  ),
                ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery, 'general'),
              icon: const Icon(Icons.add_photo_alternate, color: Colors.deepOrange),
              label: const Text("Añadir Imagen", style: TextStyle(color: Colors.deepOrange)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.deepOrange),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _guardarServicio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Guardar Servicio", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}