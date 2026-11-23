import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Mapa de ejemplo con ubicaciones y marcadores informativos en Querétaro.
class MapaPage extends StatefulWidget {
  const MapaPage({super.key});
  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  // Coordenadas aproximadas del centro de Querétaro.
  final LatLng centroQueretaro = LatLng(20.5888, -100.3899);

  // Muestra información cuando el usuario toca un marcador.
  void _mostrarInformacion(String titulo, String descripcion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(descripcion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Renderiza el mapa base, sus marcadores y la atribución de OpenStreetMap.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de lugares')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: centroQueretaro,
          initialZoom: 14,
          minZoom: 3,
          maxZoom: 19,
        ),
        children: [
          // Capa que descarga y muestra los mosaicos de OpenStreetMap.
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          // Capa de marcadores.
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(20.5888, -100.3899),
                width: 50,
                height: 60,
                child: GestureDetector(
                  onTap: () => _mostrarInformacion(
                    'Centro de Querétaro',
                    'Ubicación de referencia para la práctica.',
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color.fromARGB(255, 163, 25, 190),
                    size: 40,
                  ),
                ),
              ),

              Marker(
                point: LatLng(20.65636, -100.40507),
                width: 50,
                height: 60,
                child: GestureDetector(
                  onTap: () => _mostrarInformacion(
                    'Universidad Tecnologica de Queretaro',
                    'Ubicación de mi universidad. Celia',
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color.fromARGB(255, 31, 66, 160),
                    size: 40,
                  ),
                ),
              ),

              Marker(
                point: LatLng(20.6173, -100.3910),
                width: 50,
                height: 60,
                child: GestureDetector(
                  onTap: () => _mostrarInformacion(
                    'Punto de interés 2',
                    'Segundo marcador de ejemplo.',
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color.fromARGB(255, 203, 214, 45),
                    size: 40,
                  ),
                ),
              ),
              Marker(
                point: LatLng(20.5790, -100.4000),
                width: 50,
                height: 60,
                child: GestureDetector(
                  onTap: () => _mostrarInformacion(
                    'Punto de interés 3',
                    'Tercer marcador de ejemplo.',
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
          // Atribución obligatoria del mapa.
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution('OpenStreetMap contributors', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}
