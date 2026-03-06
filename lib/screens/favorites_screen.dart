import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ========= Favorites Screen =========
class FavoritesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> favorites;
  final Function(List<Map<String, dynamic>>) onFavoritesChanged; 
  final Function(Map<String, dynamic>)? onPlaceTap; 

  const FavoritesScreen({
    super.key, 
    required this.favorites, 
    required this.onFavoritesChanged,
    this.onPlaceTap,

  });

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No favorites yet!',
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Long press map to add places',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final place = favorites[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.location_pin, color: Colors.teal),
            title: Text(
              place['name'] ?? 'Unnamed',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (place['address'] != null && place['address'].toString().isNotEmpty) 
                Padding(  
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Icon( Icons.maps_home_work_rounded, size: 14, color: Colors.grey[600]), 
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        place['address'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 11, 
                          fontWeight: FontWeight.w500,  
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,  
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
                Text(
                  '${place['lat'].toStringAsFixed(4)}, ${place['lng'].toStringAsFixed(4)}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,  
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            onTap:() => onPlaceTap?.call(place), 
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.teal, size: 20,),
              onPressed: () {
                final updated = List<Map<String, dynamic>>.from(favorites);
                updated.removeAt(index);
                onFavoritesChanged(updated); 
              },
            ),
          ),
        );
      },
    );
  }
}
