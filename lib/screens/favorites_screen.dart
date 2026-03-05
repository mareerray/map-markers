import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


// ========= Favorites Screen =========
class FavoritesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> favorites;
  final Function(List<Map<String, dynamic>>) onFavoritesChanged; // Callback to update favorites in parent

  const FavoritesScreen({
    super.key, 
    required this.favorites, 
    required this.onFavoritesChanged
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
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final place = favorites[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.location_pin, color: Colors.teal),
            title: Text(
              place['name'] ?? 'Unnamed',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${place['lat'].toStringAsFixed(4)}, ${place['lng'].toStringAsFixed(4)}',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                final updated = List<Map<String, dynamic>>.from(favorites);
                updated.removeAt(index);
                onFavoritesChanged(updated);  // Fixed: copy list first
              },
            ),
          ),
        );
      },
    );
  }
}
