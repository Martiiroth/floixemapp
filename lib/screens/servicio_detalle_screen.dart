import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class ServicioDetalleScreen extends StatefulWidget {
  /// Ruta completa al archivo JSON del servicio
  final String archivo;

  const ServicioDetalleScreen({Key? key, required this.archivo})
      : super(key: key);

  @override
  State<ServicioDetalleScreen> createState() => _ServicioDetalleScreenState();
}

class _ServicioDetalleScreenState extends State<ServicioDetalleScreen> {
  Map<String, dynamic>? _detalle;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  /// Lee el archivo JSON del servicio y guarda su contenido en `_detalle`
  Future<void> _cargarDetalle() async {
    try {
      final file = File(widget.archivo);
      final contenido = await file.readAsString();
      setState(() {
        _detalle = jsonDecode(contenido);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar el detalle: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si aún no cargó _detalle, mostramos un indicador de carga
    if (_detalle == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Detalle del Servicio"),
          backgroundColor: Colors.red,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Detalle de servicio",
          style: TextStyle(color: Colors.white), // Título en blanco
        ),
        centerTitle: true, // Centrar el título
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(
          color: Colors.white, // Flecha "back" en blanco
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección de datos del cliente
              const Text(
                "Información del Cliente",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDetalleItem("Cliente", _detalle!['cliente']),
              _buildDetalleItem("Teléfono", _detalle!['telefono']),
              _buildDetalleItem("Email", _detalle!['email']),
              _buildDetalleItem("Dirección", _detalle!['direccion']),
              const SizedBox(height: 16),

              // Sección de detalles del servicio
              const Text(
                "Detalles del Servicio",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Muestra la fecha guardada en el JSON
              _buildDetalleItem("Fecha", _detalle!['fecha']),
              _buildDetalleItem("Tipo de Servicio", _detalle!['tipoServicio']),
              _buildDetalleItem("pH", _detalle!['ph']),
              _buildDetalleItem("Conductividad", _detalle!['conductividad']),
              _buildDetalleItem("Concentración", _detalle!['concentracion']),
              // Descripción
              _buildDetalleItem("Descripción", _detalle!['descripcion']),
              const SizedBox(height: 16),

              // Sección de productos
              const Text(
                "Productos Utilizados",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildProductosSection(),
              const SizedBox(height: 16),

              // Sección de imágenes
              const Text(
                "Imágenes del Servicio",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildImagenesSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye un item de detalle (título + valor)
  Widget _buildDetalleItem(String titulo, dynamic valor) {
    final texto = valor?.toString().trim();
    if (texto == null || texto.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$titulo: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Expanded(child: Text("No especificado")),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$titulo: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(child: Text(texto)),
          ],
        ),
      );
    }
  }

  /// Construye la sección de productos utilizados
  Widget _buildProductosSection() {
    final productos = _detalle!['productos'];

    // Si no existen o no están en la estructura esperada
    if (productos == null) {
      return const Text("No se registraron productos.");
    }

    // Suponiendo que 'productos' es una Lista de Maps: [{'nombre': 'Floixem B', 'cantidad': 2}, ...]
    if (productos is List) {
      if (productos.isEmpty) {
        return const Text("No se registraron productos.");
      }
      return Column(
        children: productos.map((prod) {
          final nombre = prod['nombre'] ?? 'Producto';
          final cantidad = prod['cantidad']?.toString() ?? '0';
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(nombre),
              Text("Cantidad: $cantidad"),
            ],
          );
        }).toList(),
      );
    }

    // Si 'productos' no es una lista, mostrar un fallback
    return const Text("Formato de productos no válido.");
  }

  /// Construye la sección de imágenes
  Widget _buildImagenesSection() {
    final imagenes = _detalle!['imagenes'];

    if (imagenes == null) {
      return const Text("No se agregaron imágenes.");
    }

    // Si tenemos una lista de rutas de imagen
    if (imagenes is List) {
      if (imagenes.isEmpty) {
        return const Text("No se agregaron imágenes.");
      }
      return SizedBox(
        height: 100,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: imagenes.map((ruta) {
            // Convertir la ruta en File e intentar mostrar la imagen
            final file = File(ruta.toString());
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Image.file(
                file,
                width: 100,
                height: 100,
                errorBuilder: (ctx, error, stack) {
                  return const Icon(Icons.broken_image, size: 80);
                },
              ),
            );
          }).toList(),
        ),
      );
    }

    return const Text("Formato de imágenes no válido.");
  }
}
