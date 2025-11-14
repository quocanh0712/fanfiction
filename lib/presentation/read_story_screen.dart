import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/work_content_model.dart';

class ReadStoryScreen extends StatefulWidget {
  final ChapterModel chapter;
  final String workTitle;
  final String author;
  final int currentChapterIndex;
  final int totalChapters;

  const ReadStoryScreen({
    super.key,
    required this.chapter,
    required this.workTitle,
    required this.author,
    required this.currentChapterIndex,
    required this.totalChapters,
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
          // FloatingActionButton synchronized with header
          Positioned(
            bottom: 100,
            right: 20,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: FloatingActionButton(
                  onPressed: () {
                    _showStoryMenuBottomSheet(context);
                  },
                  backgroundColor: Colors.grey.shade900,
                  child: Image.asset(
                    "assets/icons/ic_feature.png",
                    width: 20,
                    height: 20,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStoryMenuBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StoryMenuBottomSheet(
        chapterTitle: widget.chapter.title,
        chapterContent: widget.chapter.content,
        currentChapter:
            widget.currentChapterIndex + 1, // Convert 0-based to 1-based
        totalChapters: widget.totalChapters,
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

class _StoryMenuBottomSheet extends StatefulWidget {
  final String chapterTitle;
  final String chapterContent;
  final int currentChapter;
  final int totalChapters;

  const _StoryMenuBottomSheet({
    required this.chapterTitle,
    required this.chapterContent,
    required this.currentChapter,
    required this.totalChapters,
  });

  @override
  State<_StoryMenuBottomSheet> createState() => _StoryMenuBottomSheetState();
}

class _StoryMenuBottomSheetState extends State<_StoryMenuBottomSheet> {
  late FlutterTts flutterTts;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    flutterTts = FlutterTts();

    // Wait for TTS to be ready
    await flutterTts.awaitSpeakCompletion(true);

    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });

    flutterTts.setErrorHandler((msg) {
      print('TTS Error Handler: $msg');
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });

    flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
    });
  }

  Future<void> _toggleSpeech() async {
    try {
      if (_isPlaying) {
        await flutterTts.stop();
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      } else {
        // Clean content - remove markdown formatting
        String cleanContent = widget.chapterContent
            .replaceAll(RegExp(r'\*\*'), '') // Remove bold markers
            .replaceAll(RegExp(r'\n+'), ' ') // Replace newlines with spaces
            .trim();

        if (cleanContent.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No content to read'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // Set language - iOS uses format like 'en-US' or 'en'
        // Try 'en-US' first, fallback to 'en' if that fails
        try {
          await flutterTts.setLanguage('en-US');
        } catch (e) {
          // If en-US fails, try 'en'
          try {
            await flutterTts.setLanguage('en');
          } catch (e2) {
            print('Failed to set language: $e2');
            // Continue anyway, TTS might work with default language
          }
        }
        await flutterTts.setSpeechRate(0.5);
        await flutterTts.setVolume(1.0);
        await flutterTts.setPitch(1.0);
        await flutterTts.speak(cleanContent);
      }
    } catch (e) {
      // Handle error gracefully
      print('TTS Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TTS Error: Please rebuild the app. Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: screenHeight * 0.43,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.center,
              colors: [
                Colors.grey.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.9),
                Colors.grey.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Main content
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grab handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Center(
                      child: Container(
                        width: 200,
                        child: Text(
                          widget.chapterTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Chapter info
                    Center(
                      child: Text(
                        widget.totalChapters == 1
                            ? 'MainContent'
                            : 'Chapter ${widget.currentChapter} - (${widget.currentChapter}/${widget.totalChapters})',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 16),
                    // Audio playback section
                    GestureDetector(
                      onTap: _toggleSpeech,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Play/Pause button
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: IconButton(
                                  icon: Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.black,
                                  ),
                                  onPressed: _toggleSpeech,
                                  iconSize: 14,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Text
                            Text(
                              _isPlaying
                                  ? "Tap to pause"
                                  : "Tap 'Play' to start listening",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Headphone icon
                            Image.asset(
                              "assets/icons/ic_headphone.png",
                              width: 18,
                              height: 18,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Menu items
                    _buildMenuItem(
                      imagePath: 'assets/icons/ic_chapter_list.png',
                      title: 'Chapters',
                      onTap: () {
                        // TODO: Handle chapters
                      },
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    _buildMenuItem(
                      imagePath: 'assets/icons/ic_text_theme.png',
                      title: 'Themes',
                      onTap: () {
                        // TODO: Handle themes
                      },
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    _buildMenuItem(
                      svgPath: 'assets/icons/ic_header_robot.svg',
                      title: 'AI Assistant',
                      onTap: () {
                        // TODO: Handle AI Assistant
                      },
                    ),
                  ],
                ),
              ),
              // Progress indicator on the right
              // Positioned(
              //   top: 20,
              //   right: 20,
              //   child: Container(
              //     width: 50,
              //     height: 50,
              //     decoration: BoxDecoration(
              //       shape: BoxShape.circle,
              //       border: Border.all(color: Colors.green, width: 3),
              //     ),
              //     child: Stack(
              //       alignment: Alignment.center,
              //       children: [
              //         // Progress arc (simplified - showing 17%)
              //         SizedBox(
              //           width: 50,
              //           height: 50,
              //           child: CircularProgressIndicator(
              //             value: 0.17,
              //             strokeWidth: 3,
              //             valueColor: const AlwaysStoppedAnimation<Color>(
              //               Colors.green,
              //             ),
              //             backgroundColor: Colors.transparent,
              //           ),
              //         ),
              //         Text(
              //           '17',
              //           style: GoogleFonts.poppins(
              //             fontSize: 14,
              //             fontWeight: FontWeight.w600,
              //             color: Colors.white,
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    String? imagePath,
    String? svgPath,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            if (svgPath != null)
              SvgPicture.asset(
                svgPath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  Colors.white.withValues(alpha: 0.7),
                  BlendMode.srcIn,
                ),
              )
            else if (imagePath != null)
              Image.asset(
                imagePath,
                width: 24,
                height: 24,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
