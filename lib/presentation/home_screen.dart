import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'library_screen.dart';
import 'category_screen.dart';
import 'new_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<BottomNavItem> _navItems = [
    BottomNavItem(
      label: 'My Library',
      iconPath: 'assets/icons/ic_bottom_library.svg',
      screen: const LibraryScreen(),
    ),
    BottomNavItem(
      label: 'Category',
      iconPath: 'assets/icons/ic_bottom_category.svg',
      screen: const CategoryScreen(),
    ),
    BottomNavItem(
      label: 'New',
      iconPath: 'assets/icons/ic_bottom_new.svg',
      screen: const NewScreen(),
    ),
    BottomNavItem(
      label: 'Search',
      iconPath: 'assets/icons/ic_bottom_search.svg',
      screen: const SearchScreen(),
    ),
    BottomNavItem(
      label: 'Settings',
      iconPath: 'assets/icons/ic_bottom_setting.svg',
      screen: const SettingsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: _navItems[_selectedIndex].screen,
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70,
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            border: Border(
              top: BorderSide(
                color: Color.fromRGBO(255, 255, 255, 0.2),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _navItems.length,
                (index) => _buildNavItem(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(125, 38, 205, 0.3),
                      Color.fromRGBO(125, 38, 205, 0),
                    ],
                  ),
                  border: const Border(
                    top: BorderSide(color: Color(0xFF7d26cd), width: 2),
                  ),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 14),
              SvgPicture.asset(
                _navItems[index].iconPath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _navItems[index].label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.6),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final String label;
  final String iconPath;
  final Widget screen;

  BottomNavItem({
    required this.label,
    required this.iconPath,
    required this.screen,
  });
}
