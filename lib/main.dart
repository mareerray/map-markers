import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:map_markers/models/favorite_place.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/map_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/info_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();  // ADD
  await dotenv.load(fileName: ".env");        // ADD
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map Markers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MainTabs(), // Tab parent
    );
  }
}

// TabBar parent
class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> with TickerProviderStateMixin {
  late TabController _tabController;
  List<FavoritePlace> favorites = [];  // Shared favorites

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('favorites');
    if (jsonString != null) {
      setState(() {
        final jsonList = jsonDecode(jsonString) as List;
        favorites = jsonList.map((json) => FavoritePlace.fromJson(json)).toList();
      });  
    }
  }

  Future<void> _saveFavorites(List<FavoritePlace> newFavorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorites', json.encode(newFavorites.map((x) => x.toJson())));
    setState(() => favorites = newFavorites);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Markers',
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelColor: Colors.white.withValues(alpha:0.8),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.map), 
              text: 'Map'),
            Tab(icon: Icon(Icons.favorite), 
              text: 'Favorites'),
            Tab(icon: Icon(Icons.info), 
              text: 'Info'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MapScreen( 
            favorites: favorites.map((place) => place.toJson()).toList(), // Pass as JSON
            onFavoritesChanged: (List<Map<String, dynamic>> updatedFavorites) {
              final favoritesList = updatedFavorites.map((json) => FavoritePlace.fromJson(json)).toList();
              _saveFavorites(favoritesList);
            },
          ),
          FavoritesScreen(
            favorites: favorites.map((place) => place.toJson()).toList(), 
            onFavoritesChanged: (List<Map<String, dynamic>> updatedFavorites) {
              final favoritesList = updatedFavorites.map((json) => FavoritePlace.fromJson(json)).toList();
              _saveFavorites(favoritesList);
            },
          ),
          const InfoScreen(),
        ],
      ),
    );
  }
}

