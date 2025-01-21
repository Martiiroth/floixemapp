import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductoDetalleScreen extends StatefulWidget {
  final String nombre;
  final String imagen;
  final String descripcion;
  final List<dynamic> enlaces;

  const ProductoDetalleScreen({
    Key? key,
    required this.nombre,
    required this.imagen,
    required this.descripcion,
    required this.enlaces,
  }) : super(key: key);

  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  String? _urlSeleccionada;

  @override
  void initState() {
    super.initState();
    if (widget.enlaces.isNotEmpty) {
      _urlSeleccionada = widget.enlaces.first['url'] as String?;
    }
  }

  Future<void> _abrirEnlace(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("No se pudo abrir $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final dropdownItems = widget.enlaces.map((enlace) {
      final tienda = enlace["tienda"] ?? "Tienda";
      final url = enlace["url"] ?? "";
      return DropdownMenuItem<String>(
        value: url,
        child: Text(tienda),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombre),
        backgroundColor: Colors.red,
      ),
      // Hacemos scrolleable el contenido completo
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen con tamaño fijo (altura 250)
            SizedBox(
              height: 250,
              width: double.infinity,
              child: Image.asset(
                widget.imagen,
                fit: BoxFit.cover,
                errorBuilder: (ctx, error, stack) {
                  return const Icon(Icons.image_not_supported, size: 80);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Nombre del producto
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                widget.nombre,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            // Descripción
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(widget.descripcion),
            ),
            const SizedBox(height: 16),

            // Si hay enlaces, mostramos el dropdown y el botón
            if (widget.enlaces.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Elige la tienda",
                    border: OutlineInputBorder(),
                  ),
                  value: _urlSeleccionada,
                  items: dropdownItems,
                  onChanged: (value) {
                    setState(() {
                      _urlSeleccionada = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _urlSeleccionada == null
                      ? null
                      : () => _abrirEnlace(_urlSeleccionada!),
                  child: const Text("Comprar"),
                ),
              ),
              const SizedBox(height: 16),
            ] else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No hay tiendas disponibles para este producto."),
              ),
          ],
        ),
      ),
    );
  }
}
