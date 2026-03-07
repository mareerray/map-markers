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
  WidgetsFlutterBinding.ensureInitialized();  
  await dotenv.load(fileName: ".env");        
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  List<FavoritePlace> favorites = [];  
  Map<String, dynamic>? _selectedFavPlace;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList('favorites');  
    if (jsonList != null && jsonList.isNotEmpty) {
      setState(() {
        favorites = jsonList.map((jsonStr) => FavoritePlace.fromJson(jsonDecode(jsonStr))).toList();
      });
    }
  }

  Future<void> _saveFavorites(List<FavoritePlace> newFavorites) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = newFavorites.map((x) => jsonEncode(x.toJson())).toList();
    await prefs.setStringList('favorites', jsonList);  
    if (mounted) {
      setState(() => favorites = newFavorites);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Row(
            children: [ 
              Icon( Icons.travel_explore, color: Colors.white, size: 30, ),
              SizedBox(width: 6), 
              Text('Map Markers',
                style: GoogleFonts.limelight(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.teal,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70.0),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelColor: Colors.white.withValues(alpha:0.6),
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
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // MAP SCREEN
          MapScreen( 
            favorites: favorites.map((place) => place.toJson()).toList(), 
            onFavoritesChanged: (updated) {
              final favoritesList = updated.map((json) => FavoritePlace.fromJson(json)).toList();
              setState(() {  
                favorites = favoritesList;  
              });
              _saveFavorites(favoritesList);
            },
            onSwitchToFavorites: () {
              _tabController.animateTo(1);
            },
            selectedFavPlace: _selectedFavPlace,
          ),
          // FAVORITES SCREEN
          FavoritesScreen(
            favorites: favorites.map((place) => place.toJson()).toList(), 
            onFavoritesChanged: (List<Map<String, dynamic>> updatedFavorites) {
              final favoritesList = updatedFavorites.map((json) => FavoritePlace.fromJson(json)).toList();
              setState(() { 
                favorites = favoritesList;  
              });
              _saveFavorites(favoritesList);
            },
            onPlaceTap: (Map<String, dynamic> favoritePlace) {
              setState(() => _selectedFavPlace = favoritePlace);
              _tabController.animateTo(0); 
            },
          ),
          // INFO SCREEN
          const InfoScreen(),
        ],
      ),
    );
  }
}

