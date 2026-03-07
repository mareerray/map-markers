import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ========= Info Screen - static info about the app and developer ========

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon( Icons.travel_explore, color: Colors.teal, size: 30, ),
              SizedBox(width: 6), 
              Text(
                'Map Markers App', 
                style: GoogleFonts.limelight(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ],
          ),
          SizedBox(height: 24),
          Text(
            'Developer: Mayuree Reunsati',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            'Email: mayuree.reunsati@gritlab.ax',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
          SizedBox(height: 16),
          Text(
            'Year: 2026',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          SizedBox(height: 32),
          Text(
            'Built for Travel Tech Startup\n'
            'Save & discover your favorite places!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, height: 1.5, color: Colors.teal[700]),
          ),
          SizedBox(height: 16),
          Icon(Icons.map, size: 70, color: Colors.teal),
        ],
      ),
    );
  }
}