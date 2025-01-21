import 'package:flutter/material.dart';
import 'producto_detalle_screen.dart'; // Ajusta la ruta según tu proyecto

class TiendaScreen extends StatelessWidget {
  // Lista de productos con sus datos
  final List<Map<String, dynamic>> productos = [
    {
      "nombre": "Floixem B",
      "imagen": "lib/images/Floixem-B.png",
      "descripcion": '''
Propiedades:
• Biocida de amplio espectro, eficaz contra bacterias grampositivas, gramnegativas y levaduras.
• Prevención de hongos y algas en circuitos de baja temperatura.
• Sin restricciones de transporte o almacenamiento, seguro de manejar.

Modo de empleo y dosificación:
1. Añadir un 1% del volumen total de la instalación (por cada 1 litro de producto, se tratan hasta 100 litros de volumen).
   Suele bastar para instalaciones de hasta 12-15 radiadores o ~125 m² de suelo radiante.
2. Se pueden usar dosis de hasta el doble de la recomendada sin perjuicio del sistema.
3. Mantener la bomba de recirculación encendida (con llaves abiertas) al menos 4 horas tras añadirlo, para repartirlo homogéneamente.
4. El producto permanece activo a largo plazo.
   – Temperaturas >60 ºC y pH >8.5 pueden acelerar la pérdida de rendimiento.
''',
      "enlaces": [
        {
          "tienda": "La casa del suelo radiante",
          "url": "https://lacasadelsueloradiante.es/product/floixem-b-1l-biocioda-de-alto-espectro/"
        },
      ],
    },
    {
      "nombre": "Floixem C",
      "imagen": "lib/images/Floixem-C.png",
      "descripcion": '''
Propiedades:
• Limpia todo tipo de restos sin dañar la instalación.
• Activo a alta y baja temperatura.
• Formulación no peligrosa, no tóxica y biodegradable.
• No produce quemaduras en contacto con la piel.
• No genera humos corrosivos.

Dosificación:
• Dosificación 0,75% sobre el volumen total de la instalación.
• Por cada litro de producto se tratan 133 litros de volumen (instalaciones de 12-15 radiadores o ~125 m²).
• La concentración de aditivo se puede medir con el kit Floixem® Check.

Modo de empleo en circuitos de baja temperatura:
• Incorporar el producto y calentar hasta la temperatura de funcionamiento habitual.
• En un suelo radiante, el producto permanece 2-4 semanas mientras la instalación funciona normalmente.
• Se observa la limpieza en los colectores, restaurándose el caudal en zonas frías.
• Controlar filtros para evitar colmatación.
• Tras la limpieza, vaciar la instalación y enjuagar con agua (no es necesario neutralizar).
''',
      "enlaces": [
        {
          "tienda": "La casa del suelo radiante",
          "url": "https://lacasadelsueloradiante.es/product/floixem-c-1litro-limpiador-sistemas-de-calefaccion/"
        }
      ],
    },
    {
      "nombre": "Floixem I",
      "imagen": "lib/images/Floixem-I.png",
      "descripcion": '''
Propiedades:
• Protege de la corrosión y la incrustación el circuito.
• Elimina los ruidos térmicos en radiadores o calderas.
• Eficacia probada en aguas blandas y duras.
• Formulación no peligrosa, no tóxica y biodegradable.
• No contiene metales pesados, nitratos, nitritos ni fosfatos.
• Aumenta el rendimiento de la instalación, disminuye el consumo.
• Mayor vida útil de los equipos.
• Aprobación NSF/Buildcert.

Dosificación:
• 1% sobre el volumen total de la instalación. Por cada litro de producto se tratan 100 litros de volumen (8-10 radiadores o ~95 m² de suelo radiante).
• Incorporar el producto y dejar la bomba en marcha al menos 4 horas con todas las llaves abiertas para asegurar reparto homogéneo.

Otros:
• Los aditivos de Floixem® I no se consumen al actuar, pero se recomienda controlar anualmente el nivel de producto (por posibles fugas o rellenos).
• La concentración se mide con el kit específico Floixem® Check.
''',
      // Enlaces ejemplo (ajusta la URL real si existe)
      "enlaces": [
        {
          "tienda": "La casa del suelo radiante",
          "url": "https://lacasadelsueloradiante.es/product/floixem-i-1litro-inhibidor-corrosion/"
        }
      ],
    },
  ];

  TiendaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tienda"),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          itemCount: productos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 productos por fila
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemBuilder: (context, index) {
            final producto = productos[index];
            return InkWell(
              onTap: () {
                // Navega a la pantalla de detalle con Dropdown
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductoDetalleScreen(
                      nombre: producto["nombre"] ?? "",
                      imagen: producto["imagen"] ?? "",
                      descripcion: producto["descripcion"] ?? "",
                      enlaces: producto["enlaces"] ?? [],
                    ),
                  ),
                );
              },
              child: Card(
                elevation: 2,
                child: Column(
                  children: [
                    // Imagen
                    Expanded(
                      child: Image.asset(
                        producto["imagen"] ?? "",
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, error, stack) {
                          return const Icon(Icons.image_not_supported);
                        },
                      ),
                    ),
                    // Nombre
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        producto["nombre"] ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
