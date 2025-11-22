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
      debugShowCheckedModeBanner: false,
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
  
  final List<String> _jenisLokasi = ['Rumah', 'Toko', 'Kantor', 'Sekolah'];
  String _pilihanJenis = 'Rumah';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Tugas Mandiri 3 : Simpan dan muat data menggunakan SharedPreferences
  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(_savedNotes.map((e) => e.toJson()).toList());
    await prefs.setString('notes_data', data);
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('notes_data');
    if (data != null) {
      final List decoded = jsonDecode(data);
      setState(() {
        _savedNotes = decoded.map((e) => CatatanModel.fromJson(e)).toList();
      });
    }
  }

  // Fitur Utama
  Future<void> _findMyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
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

  void _handleLongPress(TapPosition _, latlong.LatLng point) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      point.latitude, 
      point.longitude
    );
    String address = placemarks.first.street ?? "Alamat tidak dikenal";
    
    TextEditingController noteInput = TextEditingController();
    _pilihanJenis = 'Rumah'; 

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Tambah Lokasi"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Alamat: $address", style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 10),
                TextField(
                  controller: noteInput,
                  decoration: const InputDecoration(hintText: "Tulis catatan..."),
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: _pilihanJenis,
                  isExpanded: true,
                  items: _jenisLokasi.map((String value) {
                    return DropdownMenuItem(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() => _pilihanJenis = val!);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _savedNotes.add(CatatanModel(
                      position: point,
                      note: noteInput.text.isEmpty ? "Tanpa Catatan" : noteInput.text,
                      address: address,
                      type: _pilihanJenis,
                    ));
                  });
                  _saveData();
                  Navigator.pop(ctx);
                },
                child: const Text("Simpan"),
              )
            ],
          );
        });
      },
    );
  }

  // Tugas Mandiri 2 : Hapus data
  void _hapusData(CatatanModel note) {
    setState(() {
      _savedNotes.remove(note);
    });
    _saveData();
  }

  // Tugas Mandiri 1 : kustom ikon berdasarkan jenis lokasi
  IconData _getIcon(String type) {
    if (type == 'Toko') return Icons.store;
    if (type == 'Kantor') return Icons.work;
    if (type == 'Sekolah') return Icons.school;
    return Icons.home;
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
                onTap: () {
                  showDialog(
                    context: context, 
                    builder: (ctx) => AlertDialog(
                      title: const Text("Hapus?"),
                      content: Text("Hapus ${n.note}?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                        TextButton(
                          onPressed: () {
                            _hapusData(n);
                            Navigator.pop(ctx);
                          }, 
                          child: const Text("Hapus", style: TextStyle(color: Colors.red))
                        ),
                      ],
                    )
                  );
                },
                child: Icon(_getIcon(n.type), color: Colors.red, size: 40),
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