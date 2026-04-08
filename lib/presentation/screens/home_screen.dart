import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'library_screen.dart';
import 'community_screen.dart';
import 'audio_rooms_screen.dart';
import 'profile_screen.dart';
import 'index_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const IndexScreen(),
    const LibraryScreen(),
    const CommunityScreen(),
    const AudioRoomsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
