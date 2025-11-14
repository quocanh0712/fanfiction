import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StickyHeader extends StatelessWidget {
  final String title;
  final String? backButtonText;
  final double scrollOffset;
  final VoidCallback onBackTap;
  final Widget? searchBar;
  final double searchBarHideOffset;
  final double bigTitleHideOffset;

  const StickyHeader({
    super.key,
    required this.title,
    this.backButtonText,
    required this.scrollOffset,
    required this.onBackTap,
    this.searchBar,
    this.searchBarHideOffset = 50.0,
    this.bigTitleHideOffset = 150.0,
  });

  bool _showSearchBar() {
    return scrollOffset < searchBarHideOffset;
  }

  bool _showBigTitle() {
    return scrollOffset < bigTitleHideOffset;
  }

  bool _showSmallTitle() {
    return scrollOffset >= bigTitleHideOffset;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stack để title có thể nằm chính giữa màn hình
          Stack(
            alignment: Alignment.center,
            children: [
              // Back button với text ở bên trái (ẩn text khi showSmallTitle)
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onBackTap,
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF334DCC),
                        Color(0xFF4F4CBF),
                        Color(0xFF9722C9),
                      ],
                    ).createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 28,
                        ),
                        if (backButtonText != null && !_showSmallTitle()) ...[
                          const SizedBox(width: 4),
                          Text(
                            backButtonText!,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Small title ở chính giữa màn hình với fade animation
              AnimatedOpacity(
                opacity: _showSmallTitle() ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _showSmallTitle()
                    ? Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          // Big title ẩn khi scroll >= bigTitleHideOffset
          if (_showBigTitle()) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (_showSearchBar() && searchBar != null) ...[
            const SizedBox(height: 5),
            searchBar!,
          ],
        ],
      ),
    );
  }
}
