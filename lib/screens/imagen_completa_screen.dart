import 'package:flutter/material.dart';

class ImagenCompletaScreen extends StatelessWidget {
  final String imagenUrl;

  const ImagenCompletaScreen({Key? key, required this.imagenUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true, // Permite mover la imagen
          minScale: 0.5, // Escala mínima
          maxScale: 4.0, // Escala máxima
          child: Image.network(
            imagenUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}