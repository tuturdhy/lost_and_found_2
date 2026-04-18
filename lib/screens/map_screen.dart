import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/item_service.dart';
import '../models/item_model.dart';
import 'item_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ItemService _itemService = ItemService();
  List<Marker> _markers = [];

  static const LatLng _defaultLocation = LatLng(18.0735, -15.9582);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carte des objets')),
      body: StreamBuilder<List<ItemModel>>(
        stream: _itemService.getActiveItems(),
        builder: (context, snapshot) {
          final markers = _createMarkers(snapshot.data ?? []);
          
          return FlutterMap(
            options: const MapOptions(
              initialCenter: _defaultLocation,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.lost_and_found_2',
              ),
              MarkerLayer(
                markers: markers,
              ),
            ],
          );
        },
      ),
    );
  }

  List<Marker> _createMarkers(List<ItemModel> items) {
    final markers = <Marker>[];
    
    for (final item in items) {
      if (item.latitude == 0 && item.longitude == 0) continue;
      final isLost = item.type == 'lost';
      
      markers.add(
        Marker(
          point: LatLng(item.latitude, item.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
            ),
            child: Icon(
              isLost ? Icons.location_on : Icons.check_circle,
              color: isLost ? Colors.red : Colors.green,
              size: 40,
            ),
          ),
        ),
      );
    }
    
    return markers;
  }
}