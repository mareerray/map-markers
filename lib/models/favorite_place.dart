import 'package:google_maps_flutter/google_maps_flutter.dart';

class FavoritePlace {
  final String id;
  final String name;
  final double lat;
  final double lng;

  FavoritePlace({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });

  // Convert to JSON for SharedPreferences
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lat': lat,
    'lng': lng,
  };

  // Create from JSON
  factory FavoritePlace.fromJson(Map<String, dynamic> json) => FavoritePlace(
    id: json['id'],
    name: json['name'],
    lat: json['lat'].toDouble(),
    lng: json['lng'].toDouble(),
  );

  // For markers
  Marker toMarker(void Function(FavoritePlace)? onTap) => Marker(
    markerId: MarkerId(id),
    position: LatLng(lat, lng),
    infoWindow: InfoWindow(
      title: name,
      onTap: onTap != null ? () => onTap(this) : null,
    ),
  );
}
