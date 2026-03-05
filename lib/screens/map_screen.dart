import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapScreen extends StatefulWidget {
  final List<Map<String, dynamic>> favorites;
  final Function(List<Map<String, dynamic>>) onFavoritesChanged;

  const MapScreen({
    super.key,
    required this.favorites,
    required this.onFavoritesChanged,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _PlaceSuggestion {
  final String placeId;
  final String description; 

  _PlaceSuggestion({required this.placeId, required this.description});
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _controller;
  final TextEditingController _searchController = TextEditingController();
  Set<Marker> markers = {};
  List<_PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;
  Position? _currentPosition;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(60.0971, 19.9340),
    zoom: 12.0,
  );

  // ✨✨✨✨🔑 Replace later 🔑✨✨✨✨✨
  static const String _googleApiKey = 'mykey';

  @override
  void initState() {
    super.initState();
    _updateMarkers();
  }

  void _updateMarkers() {
    markers = widget.favorites.map((place) => Marker(
      markerId: MarkerId(place['id']),
      position: LatLng(place['lat'], place['lng']),
      infoWindow: InfoWindow(
        title: place['name'],
        onTap: () => _showPlaceDialog(place),
      ),
    )).toSet();
    setState(() {});
  }

  void _showPlaceDialog(Map<String, dynamic> place) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(place['name']),
        content: Text('Lat: ${place['lat']}\nLng: ${place['lng']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchSuggestions(String input) async {
    if (input.length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isSearching = true);

    // Use current location or fallback to Mariehamn
    final lat = _currentPosition?.latitude ?? 60.0971;
    final lng = _currentPosition?.longitude ?? 19.9340;

    final url = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
      'input': input,
      'key': _googleApiKey,
      // 'types': 'establishment|address|geocode',  // Local shops + addresses
      'location': '$lat,$lng',
      'radius': '60000',  // 60km around you/Mariehamn
      'strictbounds': 'false',
      'language': 'sv',
    });

    try {
      print('Searching: $input near $lat,$lng');  // Debug
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ ${data['status']}: ${_suggestions.length} results');  // Debug
        if (data['status'] == 'OK') {
          final preds = data['predictions'] as List<dynamic>;
          setState(() {
            _suggestions = preds.map((p) => _PlaceSuggestion(
              placeId: p['place_id'] as String,
              description: p['description'] as String,
            )).toList();
          });
        } else {
          print('❌ HTTP ${response.statusCode}');
        }
      }
    } catch (e) {
      print('💥Error: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

Future<void> _goToPlace(String placeId) async {
    final url = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'place_id': placeId,
      'key': _googleApiKey,
      'fields': 'geometry/location',
    });

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'OK') {
          final loc = data['result']['geometry']['location'] as Map<String, dynamic>;
          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();

          _controller.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15),
          );
          _searchController.text = '';
          setState(() => _suggestions = []);
        }
      }
    } catch (e) {
      print('💥Error: $e');
    }
  }

  Future<void> _goToCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services disabled')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition();
      _currentPosition = position;
      setState(() {}); // Update state to show current location if needed
      _controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 15),
      );
    }
  }

@override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search places...',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : (_searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _suggestions = []);
                                    },
                                  )
                                : null),
                      ),
                      onChanged: _fetchSuggestions,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    heroTag: 'location',
                    mini: true,
                    onPressed: _goToCurrentLocation,
                    child: const Icon(Icons.my_location),
                  ),
                ],
              ),
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                    ],
                  ),
                  child: ListView.builder(
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        leading: const Icon(Icons.place, color: Colors.blue),
                        title: Text(suggestion.description),
                        onTap: () => _goToPlace(suggestion.placeId),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: GoogleMap(
            initialCameraPosition: _kGooglePlex,
            markers: markers,
            onMapCreated: (controller) => _controller = controller,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.favorites != widget.favorites) {
      _updateMarkers();
    }
  }
}