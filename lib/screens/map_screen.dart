import 'package:flutter/material.dart' hide SearchBar;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'search_bar.dart';
import 'dart:convert';
import 'dart:async';

class MapScreen extends StatefulWidget {
  final List<Map<String, dynamic>> favorites;
  final Function(List<Map<String, dynamic>>) onFavoritesChanged;
  final Map<String, dynamic>? selectedFavPlace;
  final VoidCallback? onSwitchToFavorites;

  const MapScreen({
    super.key,
    required this.favorites,
    required this.onFavoritesChanged,
    this.selectedFavPlace,
    this.onSwitchToFavorites,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _PlaceSuggestion {
  final String placeId;
  final String description; 

  const _PlaceSuggestion({
    required this.placeId, 
    required this.description
  });
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _controller;
  final TextEditingController _searchController = TextEditingController();
  Set<Marker> markers = {};
  List<_PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;
  Position? currentPosition;
  Timer? _debounceTimer;
  String apiKey = '';

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(60.0971, 19.9340),
    zoom: 12.0, // 👈 Change: 12=overview, 15=city, 18=street, 20=building
  );

  @override
  void initState() {
    super.initState();
    apiKey = dotenv.env['GOOGLE_MAP_API_KEY'] ?? '';
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _updateMarkers(); // Load markers first
    // ONE callback does it all - after screen is drawn
    if(mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.selectedFavPlace != null) {
          _focusOnFavorite(widget.selectedFavPlace!);
        }
      });
    }
  } 
  
  void _focusOnFavorite(Map<String, dynamic> place) {
    _controller.animateCamera( 
      CameraUpdate.newLatLngZoom(LatLng(place['lat'], place['lng']), 16),
    );
  } 

  Future<void> _updateMarkers() async {
      final defaultIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
    markers = widget.favorites.map((place) => Marker(
      markerId: MarkerId(place['id']),
      position: LatLng(place['lat'], place['lng']),
      icon: defaultIcon,
      infoWindow: InfoWindow(
        title: '★ ${place['name']}',
        onTap: () => _showPlaceDialog(place),
      ),
    )).toSet();
    if (mounted) setState(() {});
  }

  void _showPlaceDialog(Map<String, dynamic> place) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(place['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place['address']),
            const SizedBox(height: 12),
            Text('Lat: ${place['lat'].toStringAsFixed(4)}\nLng: ${place['lng'].toStringAsFixed(4)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _isSearching = false; // no search if empty
      });
      return;
    }

    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isSearching = true);

    final url = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
      'input': query,
      'key': apiKey,
      'language': 'en',
    });

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'OK') {
          final preds = data['predictions'] as List<dynamic>;
          setState(() {
            _suggestions = preds.map((p) => _PlaceSuggestion(
              placeId: p['place_id'] as String,
              description: p['description'] as String,
            )).toList();
            _isSearching = false;
          });
        } 
      }
      // If bad status, stop spinner
      setState(() => _isSearching = false);
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _goToPlace(String placeId) async {
    final url = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'place_id': placeId,
      'key': apiKey,
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
      //print('💥Error: $e');
    }
  }

  Future<void> _goToCurrentLocation(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return;
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
      currentPosition = position;
      setState(() {}); // Update state to show current location if needed
      _controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 15),
      );
    }
  }

  Future<void> _addMapPositionToFavorites(BuildContext context, LatLng position) async {
    // 1. Get address from lat/lng (reverse geocoding)
    final url = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '${position.latitude},${position.longitude}',
      'key': apiKey,
    });

    String autoName = 'Unnamed place';
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          autoName = data['results'][0]['formatted_address'] as String;
        }
      }
    } catch (e) {
      //print('Geocode failed: $e');
    }

    // 2. Show dialog with auto-filled name
    final nameController = TextEditingController(text: autoName);

    if (!context.mounted) return; 
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Add to favorites'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Custom name (optional)',  
                hintText: 'Home, Office, Park...',  
                border: OutlineInputBorder(),
                suffixIcon: nameController.text == autoName && nameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => nameController.clear(),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Address: $autoName',  // 👈 Confirm address saved
              style: TextStyle(fontSize: 12, color: Colors.green[600], fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            Text('Lat: ${position.latitude.toStringAsFixed(4)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text('Lng: ${position.longitude.toStringAsFixed(4)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final customName = nameController.text.trim();
              final finalName = customName.isNotEmpty ? customName : autoName.split(',')[0]; 
                final newFavoriteJson = <String, dynamic>{
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'name': finalName,       // 👈 Custom name
                  'address': autoName,      // 👈 Real address (always saved)
                  'lat': position.latitude,
                  'lng': position.longitude,
                };

                final updated = [...widget.favorites, newFavoriteJson];
                widget.onFavoritesChanged(updated);  // Triggers parent's _saveFavorites    
                _updateMarkers();
                Navigator.pop(dialogContext);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$finalName saved to favorites!'),
                  duration: Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'View',
                    onPressed: () => widget.onSwitchToFavorites?.call(),
                    textColor: Colors.white,
                  ),
                  ),
                );
              },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ------------ A lifecycle method: It detects if the favorites list has changed 
  // (e.g., a deletion in another tab) or if a new place was selected to 
  // trigger marker updates and camera animations -------------
  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.favorites != widget.favorites || 
        oldWidget.selectedFavPlace != widget.selectedFavPlace) {  
      _updateMarkers();
      if (widget.selectedFavPlace != null) {
        _focusOnFavorite(widget.selectedFavPlace!);
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // --------------------------- BUILD UI ---------------------------
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
                    child: SearchBar(
                      controller: _searchController,
                      isSearching: _isSearching,
                      suggestions: _suggestions.map((s) => '${s.placeId}|${s.description}').toList(),
                      onChanged: (value) {
                        _debounceTimer?.cancel();
                        _debounceTimer = Timer(const Duration(milliseconds: 300), () => _fetchSuggestions(value));
                      },
                      onSuggestionTap: _goToPlace,
                    ),
                  ),
                  const SizedBox(width: 8),  
                  FloatingActionButton(     
                    heroTag: 'location',
                    mini: true,
                    onPressed: () => _goToCurrentLocation(context),
                    child: const Icon(Icons.my_location),
                  ),
                ],  
              ),
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
            zoomGesturesEnabled: true,      
            scrollGesturesEnabled: true,    
            gestureRecognizers: {          
              Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
            }.toSet(),
            onLongPress: (LatLng position) => _addMapPositionToFavorites(context, position),
          ),
        ),
      ],
    );
  }
}