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
  final List<ChapterModel> allChapters; // Add all chapters list

  const ReadStoryScreen({
    super.key,
    required this.chapter,
    required this.workTitle,
    required this.author,
    required this.currentChapterIndex,
    required this.totalChapters,
    required this.allChapters,
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

  // Current chapter state (can be updated)
  late ChapterModel _currentChapter;
  late int _currentChapterIndex;

  // TTS state
  late FlutterTts flutterTts;
  bool _isPlaying = false;
  int _currentSentenceIndex = -1;
  List<String> _sentences = []; // Sentences with original format
  List<String> _cleanSentences = []; // Clean sentences for TTS
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _sentenceKeys = {};

  @override
  void initState() {
    super.initState();
    // Initialize current chapter state
    _currentChapter = widget.chapter;
    _currentChapterIndex = widget.currentChapterIndex;

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

    // Initialize TTS
    _initTts();

    // Parse content into sentences
    _parseContent();

    // Show header initially
    _animationController.forward();

    // Auto-hide after 3 seconds only on first time
    _startHideTimer();
  }

  void _updateChapter(int chapterIndex) {
    if (chapterIndex < 0 || chapterIndex >= widget.allChapters.length) return;

    // Stop TTS if playing
    if (_isPlaying) {
      flutterTts.stop();
      setState(() {
        _isPlaying = false;
        _currentSentenceIndex = -1;
      });
    }

    // Update chapter
    setState(() {
      _currentChapter = widget.allChapters[chapterIndex];
      _currentChapterIndex = chapterIndex;
      _sentences = [];
      _cleanSentences = [];
      _sentenceKeys.clear();
    });

    // Re-parse content for new chapter
    _parseContent();

    // Scroll to top
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _initTts() {
    flutterTts = FlutterTts();

    flutterTts.setCompletionHandler(() {
      // Only proceed if we're still playing and haven't been interrupted
      if (!mounted || !_isPlaying) return;

      final currentIndex = _currentSentenceIndex;

      // Verify the index is still valid
      if (currentIndex < 0 || currentIndex >= _cleanSentences.length) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _currentSentenceIndex = -1;
          });
        }
        return;
      }

      // Move to next sentence
      if (currentIndex < _cleanSentences.length - 1) {
        // Small delay to ensure TTS is ready for next sentence
        Future.delayed(const Duration(milliseconds: 100), () {
          // Double check that index hasn't changed (user might have tapped another sentence)
          if (mounted && _isPlaying && _currentSentenceIndex == currentIndex) {
            _readNextSentence(currentIndex + 1);
          }
        });
      } else {
        // Finished reading all sentences
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _currentSentenceIndex = -1;
          });
          // Restart auto-hide timer after speech finishes (only if first time)
          if (_isFirstTime) {
            _startHideTimer();
          }
        }
      }
    });

    flutterTts.setErrorHandler((msg) {
      print('TTS Error Handler: $msg');
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentSentenceIndex = -1;
        });
      }
    });

    flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = true;
          _showHeader = true; // Always show header when playing
        });
        _animationController.forward();
        _hideTimer?.cancel(); // Cancel auto-hide timer when playing
      }
    });
  }

  void _parseContent() {
    // Parse content into sentences while preserving original format
    final content = _currentChapter.content;

    // Split by sentence endings but keep original text with formatting
    final sentencePattern = RegExp(r'([.!?])\s+');
    final matches = sentencePattern.allMatches(content);

    _sentences = [];
    int lastIndex = 0;

    for (final match in matches) {
      // Include the punctuation and space
      final sentence = content.substring(lastIndex, match.end).trim();
      if (sentence.isNotEmpty) {
        _sentences.add(sentence);
      }
      lastIndex = match.end;
    }

    // Add remaining content
    if (lastIndex < content.length) {
      final remaining = content.substring(lastIndex).trim();
      if (remaining.isNotEmpty) {
        _sentences.add(remaining);
      }
    }

    // Also create clean sentences for TTS (without formatting)
    final cleanContent = content
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'\n+'), ' ');
    final cleanSentences = cleanContent
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();

    // Store clean sentences for TTS matching
    _cleanSentences = cleanSentences;

    // Create keys for each sentence
    for (int i = 0; i < _sentences.length; i++) {
      _sentenceKeys[i] = GlobalKey();
    }
  }

  Future<void> _toggleSpeech() async {
    try {
      if (_isPlaying) {
        await flutterTts.stop();
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _currentSentenceIndex = -1;
          });
          // Restart auto-hide timer after stopping (only if first time)
          if (_isFirstTime) {
            _startHideTimer();
          }
        }
      } else {
        // Show header immediately when starting to play
        if (mounted) {
          setState(() {
            _showHeader = true;
          });
          _animationController.forward();
          _hideTimer?.cancel();
        }

        if (_sentences.isEmpty) {
          _parseContent();
        }

        if (_sentences.isEmpty) {
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

        // Set language
        try {
          await flutterTts.setLanguage('en-US');
        } catch (e) {
          try {
            await flutterTts.setLanguage('en');
          } catch (e2) {
            print('Failed to set language: $e2');
          }
        }

        await flutterTts.setSpeechRate(0.5);
        await flutterTts.setVolume(1.0);
        await flutterTts.setPitch(1.0);

        // Set playing state immediately
        if (mounted) {
          setState(() {
            _isPlaying = true;
            _currentSentenceIndex = 0; // Set to first sentence
          });
        }

        // Scroll to first sentence immediately when starting to play
        // Use multiple attempts to ensure scroll works even from bottom of page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToTop();
        });

        // Start reading sentence by sentence
        _readNextSentence(0);
      }
    } catch (e) {
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
          _currentSentenceIndex = -1;
        });
      }
    }
  }

  Future<void> _startFromSentence(int index) async {
    if (index < 0 || index >= _cleanSentences.length) return;

    // Stop current speech completely
    try {
      await flutterTts.stop();
      // Wait a bit to ensure TTS is fully stopped
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print('Error stopping TTS: $e');
    }

    // Update current sentence index immediately
    if (mounted) {
      setState(() {
        _currentSentenceIndex = index;
      });
    }

    // Scroll to the selected sentence
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSentence(index);
    });

    // Wait a bit for scroll to complete and TTS to be ready
    await Future.delayed(const Duration(milliseconds: 400));

    // Start reading from the selected sentence
    // Ensure we're still playing before starting
    if (mounted && _isPlaying) {
      // Reset any pending completion handlers by directly calling readNextSentence
      _readNextSentence(index);
    }
  }

  Future<void> _readNextSentence(int index) async {
    // Double check that we should continue
    if (index >= _cleanSentences.length || !_isPlaying) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentSentenceIndex = -1;
        });
      }
      return;
    }

    // Update current sentence index
    if (mounted) {
      setState(() {
        _currentSentenceIndex = index;
      });
    }

    // Scroll to current sentence (only if not the first sentence to avoid conflicts)
    if (index > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSentence(index);
      });
    }

    // Read current sentence using clean sentence for TTS
    // completion handler will call next sentence
    try {
      await flutterTts.speak(_cleanSentences[index]);
    } catch (e) {
      print('Error speaking sentence $index: $e');
      // If error, try to continue with next sentence
      if (mounted && _isPlaying && index < _cleanSentences.length - 1) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _isPlaying) {
            _readNextSentence(index + 1);
          }
        });
      }
    }
  }

  void _scrollToTop() {
    // Directly scroll to top using scroll controller
    if (!_scrollController.hasClients) {
      // If scroll controller is not ready, wait a bit and try again
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _scrollToTop();
        }
      });
      return;
    }

    // Try multiple approaches to ensure scroll works
    // Method 1: Direct animateTo
    try {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      print('Error animating to top: $e');
    }

    // Method 2: Also try jumpTo as fallback
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients && mounted) {
        try {
          if (_scrollController.offset > 0) {
            _scrollController.jumpTo(0);
          }
        } catch (e) {
          print('Error jumping to top: $e');
        }
      }
    });

    // Method 3: Ensure first sentence is visible after scroll
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _sentenceKeys.containsKey(0)) {
        final key = _sentenceKeys[0];
        if (key?.currentContext != null) {
          try {
            Scrollable.ensureVisible(
              key!.currentContext!,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: 0.0,
            );
          } catch (e) {
            print('Error ensuring visible: $e');
          }
        }
      }
    });
  }

  void _scrollToSentence(int index) {
    if (!_scrollController.hasClients) {
      // If scroll controller is not ready, wait a bit and try again
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients && mounted) {
          _scrollToSentence(index);
        }
      });
      return;
    }

    // For first sentence, use scroll to top
    if (index == 0) {
      _scrollToTop();
      return;
    }

    final key = _sentenceKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.3, // Show sentence at 30% from top
      );
    } else {
      // If context is not ready, wait a bit and try again
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _scrollToSentence(index);
        }
      });
    }
  }

  void _startHideTimer() {
    // Only auto-hide on first time and when not playing
    if (!_isFirstTime || _isPlaying) return;

    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showHeader && _isFirstTime && !_isPlaying) {
        setState(() {
          _showHeader = false;
          _isFirstTime = false; // Mark as no longer first time
        });
        _animationController.reverse();
      }
    });
  }

  void _toggleHeader() {
    // Don't allow hiding header when TTS is playing
    if (_isPlaying && !_showHeader) {
      setState(() {
        _showHeader = true;
      });
      _animationController.forward();
      return;
    }

    // Don't allow hiding when playing
    if (_isPlaying) return;

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
    _scrollController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Content area
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 50,
                bottom: 10,
              ),
              child: _buildFormattedContent(_currentChapter.content),
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
                        // Pause button on the left (only show when playing)
                        if (_isPlaying)
                          Positioned(
                            top: 37,
                            left: 0,
                            child: IconButton(
                              icon: const Icon(
                                Icons.pause,
                                color: Colors.white,
                              ),
                              onPressed: _toggleSpeech,
                              iconSize: 24,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        // Title centered with fixed width
                        Positioned(
                          top: 50,
                          left: _isPlaying ? 40 : 0,
                          right: 0,
                          child: Center(
                            child: SizedBox(
                              width:
                                  MediaQuery.of(context).size.width -
                                  32 - // padding left + right
                                  48 - // IconButton width
                                  (_isPlaying ? 40 : 0) - // Pause button width
                                  16, // margin
                              child: Text(
                                _currentChapter.title,
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
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setBottomSheetState) {
          return _StoryMenuBottomSheet(
            chapterTitle: _currentChapter.title,
            chapterContent: _currentChapter.content,
            currentChapter:
                _currentChapterIndex + 1, // Convert 0-based to 1-based
            totalChapters: widget.totalChapters,
            allChapters: widget.allChapters,
            isPlaying: _isPlaying,
            workTitle: widget.workTitle,
            onChapterTap: (index) {
              _updateChapter(index);
              // Update bottom sheet to show new chapter info
              setBottomSheetState(() {});
              setState(() {
                // Also update parent state
              });
            },
            onPlayPauseTap: () async {
              // Close bottom sheet first
              Navigator.of(context).pop();
              // Wait a bit for bottom sheet to close completely and ListView to be ready
              await Future.delayed(const Duration(milliseconds: 500));
              // Then toggle speech
              if (mounted) {
                _toggleSpeech();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildFormattedContent(String content) {
    // Always render content by sentences
    // Parse if not already parsed
    if (_sentences.isEmpty) {
      _parseContent();
    }
    return _buildSentenceBasedContent(content);
  }

  Widget _buildSentenceBasedContent(String content) {
    // Use ListView.builder for better performance with lazy loading
    return ListView.builder(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      cacheExtent: 500, // Cache more items for smoother scrolling
      itemCount: _sentences.length,
      itemBuilder: (context, index) {
        final sentence = _sentences[index];
        // Only highlight when playing, otherwise all sentences are normal white
        final isCurrentSentence = _isPlaying && _currentSentenceIndex == index;
        final isDimmed = _isPlaying && _currentSentenceIndex != index;

        // Use RepaintBoundary to isolate repaints and improve performance
        Widget sentenceWidget;
        if (sentence.contains('**')) {
          sentenceWidget = _buildBoldTextWithHighlight(
            sentence,
            isCurrentSentence,
            isDimmed,
          );
        } else {
          sentenceWidget = _buildTextWithHighlight(
            sentence,
            GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 1.6,
            ),
            isCurrentSentence,
            isDimmed,
          );
        }

        return RepaintBoundary(
          key: _sentenceKeys[index],
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // If playing, allow user to tap a sentence to start from there
              if (_isPlaying) {
                _startFromSentence(index);
              } else {
                // If not playing, toggle header
                _toggleHeader();
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: sentenceWidget,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLineBasedContent(String content) {
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

  Widget _buildTextWithHighlight(
    String text,
    TextStyle style,
    bool isCurrent,
    bool isDimmed,
  ) {
    // If not playing, use normal white color
    // If playing: current sentence is white, others are dimmed
    return Text(
      text,
      style: style.copyWith(
        color: isCurrent
            ? Colors.white
            : (isDimmed ? Colors.white.withValues(alpha: 0.4) : Colors.white),
      ),
    );
  }

  Widget _buildTextWithHighlightOld(String text, TextStyle style) {
    // If not playing, return normal text
    if (!_isPlaying ||
        _currentSentenceIndex < 0 ||
        _currentSentenceIndex >= _sentences.length) {
      return Text(text, style: style);
    }

    // Find current sentence (clean version)
    final currentSentence = _sentences[_currentSentenceIndex];
    // Remove bold markers and normalize for comparison
    final cleanText = text.replaceAll(RegExp(r'\*\*'), '');

    // Check if this line contains the current sentence
    final containsCurrentSentence = cleanText.contains(currentSentence);

    if (containsCurrentSentence) {
      // Highlight current sentence, dim the rest
      return _buildHighlightedText(text, currentSentence, style);
    } else {
      // Dim the entire line if it doesn't contain current sentence
      return Text(
        text,
        style: style.copyWith(color: Colors.white.withValues(alpha: 0.4)),
      );
    }
  }

  Widget _buildHighlightedText(
    String text,
    String highlightSentence,
    TextStyle baseStyle,
  ) {
    // Remove bold markers for comparison
    final cleanText = text.replaceAll(RegExp(r'\*\*'), '');
    final cleanHighlight = highlightSentence;

    final highlightIndex = cleanText.indexOf(cleanHighlight);
    if (highlightIndex == -1) {
      // If can't find exact match, just dim the whole line
      return Text(
        text,
        style: baseStyle.copyWith(color: Colors.white.withValues(alpha: 0.4)),
      );
    }

    // Build text spans with highlight
    final List<TextSpan> spans = [];

    // Text before highlight
    if (highlightIndex > 0) {
      final beforeText = text.substring(0, highlightIndex);
      spans.add(
        TextSpan(
          text: beforeText,
          style: baseStyle.copyWith(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );
    }

    // Highlighted text (need to find original text with formatting)
    final highlightEnd = highlightIndex + cleanHighlight.length;
    final highlightedText = text.substring(
      highlightIndex,
      highlightEnd < text.length ? highlightEnd : text.length,
    );
    spans.add(
      TextSpan(
        text: highlightedText,
        style: baseStyle.copyWith(color: Colors.white),
      ),
    );

    // Text after highlight
    if (highlightEnd < text.length) {
      final afterText = text.substring(highlightEnd);
      spans.add(
        TextSpan(
          text: afterText,
          style: baseStyle.copyWith(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildBoldTextWithHighlight(
    String text,
    bool isCurrent,
    bool isDimmed,
  ) {
    // Parse text with **bold** markers
    final List<TextSpan> spans = [];
    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
    // If not playing, use normal white color
    // If playing: current sentence is white, others are dimmed
    final baseColor = isCurrent
        ? Colors.white
        : (isDimmed ? Colors.white.withValues(alpha: 0.4) : Colors.white);

    int lastIndex = 0;
    for (final match in boldRegex.allMatches(text)) {
      // Add text before bold
      if (match.start > lastIndex) {
        final beforeText = text.substring(lastIndex, match.start);
        spans.add(
          TextSpan(
            text: beforeText,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: baseColor,
              height: 1.6,
            ),
          ),
        );
      }

      // Add bold text
      final boldText = match.group(1)!;
      spans.add(
        TextSpan(
          text: boldText,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: baseColor,
            height: 1.6,
          ),
        ),
      );

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      final remainingText = text.substring(lastIndex);
      spans.add(
        TextSpan(
          text: remainingText,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: baseColor,
            height: 1.6,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: GoogleFonts.poppins(fontSize: 12, height: 1.6, color: baseColor),
      ),
    );
  }

  Widget _buildBoldTextWithHighlightOld(String text) {
    // If not playing, use normal bold text
    if (!_isPlaying ||
        _currentSentenceIndex < 0 ||
        _currentSentenceIndex >= _sentences.length) {
      return _buildBoldText(text);
    }

    // Parse text with **bold** markers and highlight
    final List<TextSpan> spans = [];
    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
    final currentSentence = _sentences[_currentSentenceIndex];
    final cleanText = text.replaceAll(RegExp(r'\*\*'), '');

    int lastIndex = 0;
    for (final match in boldRegex.allMatches(text)) {
      // Add text before bold
      if (match.start > lastIndex) {
        final beforeText = text.substring(lastIndex, match.start);
        spans.add(
          TextSpan(
            text: beforeText,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: cleanText.contains(currentSentence)
                  ? _getTextColorForSentence(beforeText, currentSentence)
                  : Colors.white.withValues(alpha: 0.4),
            ),
          ),
        );
      }

      // Add bold text
      final boldText = match.group(1)!;
      spans.add(
        TextSpan(
          text: boldText,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: cleanText.contains(currentSentence)
                ? _getTextColorForSentence(boldText, currentSentence)
                : Colors.white.withValues(alpha: 0.4),
          ),
        ),
      );

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      final remainingText = text.substring(lastIndex);
      spans.add(
        TextSpan(
          text: remainingText,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: cleanText.contains(currentSentence)
                ? _getTextColorForSentence(remainingText, currentSentence)
                : Colors.white.withValues(alpha: 0.4),
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

  Color _getTextColorForSentence(String text, String currentSentence) {
    final cleanText = text.replaceAll(RegExp(r'\*\*'), '');
    if (cleanText.contains(currentSentence)) {
      return Colors.white; // Highlight
    }
    return Colors.white.withValues(alpha: 0.4); // Dim
  }
}

class _StoryMenuBottomSheet extends StatefulWidget {
  final String chapterTitle;
  final String chapterContent;
  final int currentChapter;
  final int totalChapters;
  final List<ChapterModel> allChapters;
  final bool isPlaying;
  final Function(int)? onChapterTap;
  final VoidCallback? onPlayPauseTap;
  final String workTitle;

  const _StoryMenuBottomSheet({
    required this.chapterTitle,
    required this.chapterContent,
    required this.currentChapter,
    required this.totalChapters,
    required this.allChapters,
    required this.isPlaying,
    required this.workTitle,
    this.onChapterTap,
    this.onPlayPauseTap,
  });

  @override
  State<_StoryMenuBottomSheet> createState() => _StoryMenuBottomSheetState();
}

class _StoryMenuBottomSheetState extends State<_StoryMenuBottomSheet> {
  // TTS is handled by parent screen, bottom sheet just triggers it
  bool _showChaptersList = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: _showChaptersList ? screenHeight * 0.7 : screenHeight * 0.43,
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
                          widget.workTitle,
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
                      onTap: () {
                        // Close bottom sheet and toggle speech
                        if (widget.onPlayPauseTap != null) {
                          widget.onPlayPauseTap!();
                        }
                      },
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
                                    widget.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    // Close bottom sheet and toggle speech
                                    if (widget.onPlayPauseTap != null) {
                                      widget.onPlayPauseTap!();
                                    }
                                  },
                                  iconSize: 14,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Text
                            Text(
                              widget.isPlaying
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
                        setState(() {
                          _showChaptersList = !_showChaptersList;
                        });
                      },
                    ),
                    // Chapters list (shown when _showChaptersList is true)
                    if (_showChaptersList) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24, height: 1),
                      SizedBox(
                        height: 200, // Fixed height for chapters list
                        child: ListView.separated(
                          itemCount: widget.allChapters.length,
                          separatorBuilder: (context, index) =>
                              const Divider(color: Colors.white24, height: 1),
                          itemBuilder: (context, index) {
                            final chapter = widget.allChapters[index];
                            final isSelected =
                                widget.currentChapter == index + 1;

                            // Extract chapter title (remove "Chapter X:" prefix if exists)
                            String displayTitle = chapter.title;
                            if (displayTitle.contains(':')) {
                              final parts = displayTitle.split(':');
                              if (parts.length > 1) {
                                displayTitle = parts
                                    .sublist(1)
                                    .join(':')
                                    .trim();
                              }
                            }

                            return InkWell(
                              onTap: () {
                                if (widget.onChapterTap != null) {
                                  widget.onChapterTap!(index);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    // Chapter number indicator
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white.withValues(
                                                  alpha: 0.3,
                                                ),
                                          width: 1,
                                        ),
                                        color: isSelected
                                            ? Colors.white.withValues(
                                                alpha: 0.2,
                                              )
                                            : Colors.transparent,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.white.withValues(
                                                    alpha: 0.7,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Chapter title
                                    Expanded(
                                      child: Text(
                                        displayTitle.isEmpty
                                            ? chapter.title
                                            : displayTitle,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white.withValues(
                                                  alpha: 0.7,
                                                ),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
