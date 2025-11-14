import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/work_content_model.dart';

class ReadStoryScreen extends StatefulWidget {
  final ChapterModel chapter;
  final String workTitle;
  final String author;

  const ReadStoryScreen({
    super.key,
    required this.chapter,
    required this.workTitle,
    required this.author,
  });

  @override
  State<ReadStoryScreen> createState() => _ReadStoryScreenState();
}

class _ReadStoryScreenState extends State<ReadStoryScreen>
    with SingleTickerProviderStateMixin {
  bool _showHeader = true;
  bool _isFirstTime = true;
  Timer? _hideTimer;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Show header initially
    _animationController.forward();

    // Auto-hide after 3 seconds only on first time
    _startHideTimer();
  }

  void _startHideTimer() {
    // Only auto-hide on first time
    if (!_isFirstTime) return;

    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showHeader && _isFirstTime) {
        setState(() {
          _showHeader = false;
          _isFirstTime = false; // Mark as no longer first time
        });
        _animationController.reverse();
      }
    });
  }

  void _toggleHeader() {
    // Mark as no longer first time when user interacts
    if (_isFirstTime) {
      _isFirstTime = false;
      _hideTimer?.cancel(); // Cancel auto-hide timer
    }

    setState(() {
      _showHeader = !_showHeader;
    });

    if (_showHeader) {
      _animationController.forward();
      // Don't start timer again after first time
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Content area with tap detection
          GestureDetector(
            onTap: _toggleHeader,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 50,
                  bottom: 10,
                ),
                child: _buildFormattedContent(widget.chapter.content),
              ),
            ),
          ),
          // Sticky header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    height: 100,
                    color: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Title centered with fixed width
                        Positioned(
                          top: 50,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SizedBox(
                              width:
                                  MediaQuery.of(context).size.width -
                                  32 - // padding left + right
                                  48 - // IconButton width
                                  16, // margin
                              child: Text(
                                widget.chapter.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        // Close button aligned to right and same height as title
                        Positioned(
                          top: 37,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => context.pop(),
                            iconSize: 24,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedContent(String content) {
    // Split content by newlines
    final lines = content.split('\n');
    final List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) {
        // Add spacing for empty lines
        widgets.add(const SizedBox(height: 16));
        continue;
      }

      // Check if line is a heading (starts and ends with ** or is all caps)
      final isFullBoldHeading =
          line.startsWith('**') && line.endsWith('**') && line.length > 4;
      final isCapsHeading =
          line.length > 0 &&
          line == line.toUpperCase() &&
          line.length < 50 &&
          !line.contains('**');

      // Check for bold text (**text**)
      if (line.contains('**')) {
        if (isFullBoldHeading) {
          // Full line is bold heading
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 8),
              child: Text(
                line.replaceAll('**', ''),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          );
        } else {
          // Mixed bold and normal text
          widgets.add(_buildBoldText(line));
        }
      } else if (isCapsHeading) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Text(
              line,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              line,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                height: 1.6,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildBoldText(String text) {
    // Parse text with **bold** markers
    final List<TextSpan> spans = [];
    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');

    int lastIndex = 0;
    for (final match in boldRegex.allMatches(text)) {
      // Add text before bold
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        );
      }

      // Add bold text
      spans.add(
        TextSpan(
          text: match.group(1),
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        text: TextSpan(
          children: spans,
          style: GoogleFonts.poppins(
            fontSize: 15,
            height: 1.6,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
