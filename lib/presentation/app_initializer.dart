import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../repositories/category_repository.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bubbleCtl;
  late final Animation<double> _scale;
  late final Animation<double> _offset;
  final CategoryRepository _categoryRepository = CategoryRepository();

  @override
  void initState() {
    super.initState();
    _bubbleCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scale = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _bubbleCtl, curve: Curves.easeInOut));

    _offset = Tween<double>(
      begin: -6.0,
      end: 6.0,
    ).animate(CurvedAnimation(parent: _bubbleCtl, curve: Curves.easeInOut));

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Delay nhỏ để hiển thị UI
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      try {
        // Load critical data
        await _categoryRepository.loadCategories();

        // Wait minimum 1 second for better UX
        await Future.delayed(const Duration(milliseconds: 700));

        if (mounted) {
          _navigateToSplash();
        }
      } catch (e) {
        // Even if error, navigate to splash
        // Categories can be loaded later
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          _navigateToSplash();
        }
      }
    }
  }

  void _navigateToSplash() {
    context.go('/');
  }

  @override
  void dispose() {
    _bubbleCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF121212),
                    const Color(0xFF1a0d2e),
                    const Color(0xFF7d26cd).withOpacity(0.3),
                  ],
                ),
              ),
            ),

            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  AnimatedBuilder(
                    animation: _bubbleCtl,
                    builder: (_, __) {
                      return Transform.translate(
                        offset: Offset(0, _offset.value),
                        child: Transform.scale(
                          scale: _scale.value,
                          child: Container(
                            padding: EdgeInsets.all(20),
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7d26cd),
                              border: Border.all(
                                color: const Color(0xFF37393f),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: SvgPicture.asset(
                              'assets/images/img_book.svg',
                              width: 130,
                              height: 108,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Title with gradient
                  ShaderMask(
                    shaderCallback: (Rect bounds) =>
                        const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFF7d26cd),
                            Color(0xFF9d4edd),
                            Colors.white,
                          ],
                        ).createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                    blendMode: BlendMode.srcIn,
                    child: Column(
                      children: [
                        Text(
                          'Loading Stories',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'For You...',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Preparing your personalized\nfanfiction reading experience',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Loading indicator
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: Color(0xFF7d26cd),
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
