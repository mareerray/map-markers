import 'package:flutter/material.dart';
import 'dart:async'; // For controller
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For Google Maps

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Completer<GoogleMapController> _controller = Completer();

  //Start at Mariehamn
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(60.0971, 19.9340),
    zoom: 12.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Map Markers',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          )
        ),
        // centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        myLocationEnabled: true,    // Show blue dot (your location)
        myLocationButtonEnabled: true, // Location button
      ),    
    );
  }
}