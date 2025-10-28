import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  final int selectedIndex;
  final Widget child;

  const HomeScreen({
    super.key,
    required this.selectedIndex,
    required this.child,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<BottomNavItem> _navItems = [
    BottomNavItem(
      label: 'My Library',
      iconPath: 'assets/icons/ic_bottom_library.svg',
      route: '/home/library',
    ),
    BottomNavItem(
      label: 'Category',
      iconPath: 'assets/icons/ic_bottom_category.svg',
      route: '/home/category',
    ),
    BottomNavItem(
      label: 'New',
      iconPath: 'assets/icons/ic_bottom_new.svg',
      route: '/home/new',
    ),
    BottomNavItem(
      label: 'Search',
      iconPath: 'assets/icons/ic_bottom_search.svg',
      route: '/home/search',
    ),
    BottomNavItem(
      label: 'Settings',
      iconPath: 'assets/icons/ic_bottom_setting.svg',
      route: '/home/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: widget.child,
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70,
          decoration: const BoxDecoration(
            color: const Color(0xFF121212),
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
    final isSelected = widget.selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => context.go(_navItems[index].route),
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color.fromRGBO(125, 38, 205, 0.3),
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
  final String route;

  BottomNavItem({
    required this.label,
    required this.iconPath,
    required this.route,
  });
}
