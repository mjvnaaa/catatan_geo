import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'catatan_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<CatatanModel> _savedNotes = [];
  final MapController _mapController = MapController();

  final List<String> _locationTypes = ['Rumah', 'Toko', 'Kantor', 'Taman'];
  String _selectedType = 'Rumah';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      _savedNotes.map((note) => note.toJson()).toList()
    );
    await prefs.setString('saved_notes', encodedData);
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('saved_notes');

    if (encodedData != null) {
      final List<dynamic> decodedData = jsonDecode(encodedData);
      setState(() {
        _savedNotes = decodedData
            .map((item) => CatatanModel.fromJson(item))
            .toList();
      });
    }
  }

  Future<void> _findMyLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    _mapController.move(
      latlong.LatLng(position.latitude, position.longitude),
      15.0,
    );
  }

  void _handleLongPress(TapPosition tapPosition, latlong.LatLng point) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      point.latitude, 
      point.longitude
    );
    
    String address = placemarks.first.street ?? "Alamat tidak dikenal";
    TextEditingController noteController = TextEditingController();

    setState(() {
      _selectedType = 'Rumah';
    });

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Tambah Lokasi"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Alamat: $address", style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: "Catatan"),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    items: _locationTypes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setDialogState(() {
                        _selectedType = newValue!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _savedNotes.add(CatatanModel(
                        position: point,
                        note: noteController.text.isEmpty ? "Tanpa Catatan" : noteController.text,
                        address: address,
                        type: _selectedType,
                      ));
                    });
                    _saveNotes();
                    Navigator.pop(context);
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getIconByType(String type) {
    switch (type) {
      case 'Toko': return Icons.store;
      case 'Kantor': return Icons.work;
      case 'Taman': return Icons.park;
      case 'Rumah': default: return Icons.home;
    }
  }

  void _deleteNote(CatatanModel note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Lokasi?"),
        content: Text("Yakin ingin menghapus ${note.note}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _savedNotes.remove(note);
              });
              _saveNotes();
              Navigator.pop(ctx);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Geo-Catatan")),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const latlong.LatLng(-6.2, 106.8),
          initialZoom: 13.0,
          onLongPress: _handleLongPress,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          MarkerLayer(
            markers: _savedNotes.map((n) => Marker(
              point: n.position,
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _deleteNote(n),
                child: Icon(
                  _getIconByType(n.type),
                  color: Colors.red,
                  size: 40,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _findMyLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}