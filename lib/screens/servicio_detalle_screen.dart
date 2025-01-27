import 'package:flutter/material.dart';
import 'imagen_completa_screen.dart'; // Pantalla para ver imágenes en grande

class ServicioDetalleScreen extends StatelessWidget {
  final Map<String, dynamic> visita; // Recibe la visita como parámetro

  const ServicioDetalleScreen({Key? key, required this.visita}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extraer los datos de la visita
    final fecha = visita['fecha'] ?? 'Sin Fecha';
    final direccion = visita['direccion'] ?? 'Sin Dirección';
    final descripcion = visita['descripcion'] ?? 'Sin Descripción';
    final defectos = visita['defectos'] ?? 'Sin Defectos';
    final tipoServicio = visita['tipoServicio'] ?? 'Sin Tipo de Servicio';
    final ph = visita['ph'] ?? 'Sin pH';
    final conductividad = visita['conductividad'] ?? 'Sin Conductividad';
    final concentracion = visita['concentracion'] ?? 'Sin Concentración';
    final productos = visita['productos'] ?? [];
    final imagenes = visita['imagenes'] ?? [];
    final phImage = visita['phImage'] ?? '';
    final conductividadImage = visita['conductividadImage'] ?? '';
    final concentracionImage = visita['concentracionImage'] ?? '';
    final proximaVisita = visita['proximaVisita'] ?? 'Sin Próxima Visita';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalles del Servicio"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de detalles generales
            const Text(
              "Detalles Generales",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDetailRow("Fecha", fecha),
            _buildDetailRow("Dirección", direccion),
            _buildDetailRow("Descripción", descripcion),
            _buildDetailRow("Defectos", defectos),
            _buildDetailRow("Tipo de Servicio", tipoServicio),
            _buildDetailRow("pH", ph),
            _buildDetailRow("Conductividad", conductividad),
            _buildDetailRow("Concentración", concentracion),
            _buildDetailRow("Próxima Visita", proximaVisita),
            const SizedBox(height: 16),

            // Sección de productos utilizados
            const Text(
              "Productos Utilizados",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (productos.isEmpty)
              const Text("No se utilizaron productos.")
            else
              Column(
                children: productos.map<Widget>((producto) {
                  return ListTile(
                    title: Text(producto['nombre'] ?? 'Sin Nombre'),
                    subtitle: Text("Cantidad: ${producto['cantidad'] ?? 0}"),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),

            // Sección de imágenes asociadas a pH, conductividad y concentración
            if (phImage.isNotEmpty || conductividadImage.isNotEmpty || concentracionImage.isNotEmpty) ...[
              const Text(
                "Imágenes Asociadas",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (phImage.isNotEmpty) _buildImageSection(context, "Imagen de pH", phImage),
              if (conductividadImage.isNotEmpty) _buildImageSection(context, "Imagen de Conductividad", conductividadImage),
              if (concentracionImage.isNotEmpty) _buildImageSection(context, "Imagen de Concentración", concentracionImage),
              const SizedBox(height: 16),
            ],

            // Sección de imágenes generales del servicio
            const Text(
              "Imágenes del Servicio",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (imagenes.isEmpty)
              const Text("No hay imágenes registradas.")
            else
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imagenes.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // Navegar a la pantalla de imagen en grande
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImagenCompletaScreen(
                              imagenUrl: imagenes[index],
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Hero(
                          tag: imagenes[index], // Usar la URL como tag único
                          child: Image.network(
                            imagenes[index],
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error); // Muestra un ícono de error si la imagen no se carga
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Método para construir una fila de detalle
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// Método para construir una sección de imagen con título
  Widget _buildImageSection(BuildContext context, String title, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            // Navegar a la pantalla de imagen en grande
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImagenCompletaScreen(
                  imagenUrl: imageUrl,
                ),
              ),
            );
          },
          child: Image.network(
            imageUrl,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error); // Muestra un ícono de error si la imagen no se carga
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}