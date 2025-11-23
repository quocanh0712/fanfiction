import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/work_content_model.dart';
import '../services/app_preferences_service.dart';

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

  // Theme settings
  int _fontSizeOffset = 0; // 0 to 10 (default 10, each increment adds 2)
  int _initialTextSize =
      10; // Text size from settings (used to calculate max offset)
  String _fontFamily = 'Default'; // Default, Times New Roman, etc.
  String _themeMode = 'Default'; // Default, Light, Paper, Calm, Light blue

  // TTS state
  late FlutterTts flutterTts;
  bool _isPlaying = false;
  int _currentSentenceIndex = -1;
  List<String> _sentences = []; // Sentences with original format
  List<String> _cleanSentences = []; // Clean sentences for TTS
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _sentenceKeys = {};
  final AppPreferencesService _appPreferencesService = AppPreferencesService();

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

    // Load theme and text size from preferences
    _loadThemeMode();
    _loadTextSize();
    _loadTTSVoice();

    // Initialize TTS
    _initTts();

    // Load available voices after TTS is initialized (async, no await needed)
    _loadAvailableVoices();

    // Parse content into sentences
    _parseContent();

    // Show header initially
    _animationController.forward();

    // Auto-hide after 3 seconds only on first time
    _startHideTimer();
  }

  Future<void> _loadThemeMode() async {
    try {
      final themeMode = await _appPreferencesService.getThemeMode();
      if (mounted) {
        setState(() {
          _themeMode = themeMode;
        });
      }
    } catch (e) {
      print('Error loading theme mode: $e');
    }
  }

  Future<void> _loadTextSize() async {
    try {
      final textSize = await _appPreferencesService.getTextSize();
      if (mounted) {
        setState(() {
          // Store initial text size from settings
          _initialTextSize = textSize;
          // Convert text size to offset
          // actualFontSize = baseFontSize (10) + offset
          // So: offset = textSize - 10
          // Text size 10 = offset 0, 12 = 2, 14 = 4, 16 = 6, 18 = 8, 20 = 10
          _fontSizeOffset = textSize - 10;
        });
      }
    } catch (e) {
      print('Error loading text size: $e');
    }
  }

  String? _ttsVoice;
  String _ttsLanguage = 'en-US';
  List<Map<String, String>> _availableVoices = [];

  Future<void> _loadTTSVoice() async {
    try {
      final voice = await _appPreferencesService.getTTSVoice();
      final language = await _appPreferencesService.getTTSLanguage();
      if (mounted) {
        setState(() {
          _ttsVoice = voice;
          _ttsLanguage = language;
        });
      }
      // Load available voices to find the correct locale for the selected voice
      await _loadAvailableVoices();
    } catch (e) {
      print('Error loading TTS voice: $e');
    }
  }

  Future<void> _loadAvailableVoices() async {
    try {
      final voices = await flutterTts.getVoices;
      if (mounted) {
        setState(() {
          _availableVoices = List<Map<String, String>>.from(
            voices.map(
              (voice) => {
                'name': voice['name']?.toString() ?? '',
                'locale': voice['locale']?.toString() ?? '',
              },
            ),
          );
        });
      }
    } catch (e) {
      print('Error loading available voices: $e');
    }
  }

  String? _getVoiceLocale(String voiceName) {
    // Find the locale for the given voice name
    try {
      final voice = _availableVoices.firstWhere(
        (v) => v['name'] == voiceName,
        orElse: () => {},
      );
      return voice['locale'];
    } catch (e) {
      return null;
    }
  }

  // Calculate max offset based on initial text size from settings
  // Max offset allows only 1 more increment from initial text size
  int _getMaxOffset() {
    // Convert initial text size to offset
    // Text size 10 = offset 0, 12 = 2, 14 = 4, 16 = 6, 18 = 8, 20 = 10
    final initialOffset = _initialTextSize - 10;
    // Max offset allows only 1 more increment (add 2 to offset)
    // This ensures user can only increase by 1 step from their settings
    final maxOffset = initialOffset + 2;
    // But don't exceed the absolute max of 10 (text size 20)
    return maxOffset.clamp(0, 10);
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

    // Scroll to top after content is rendered
    // Wait for ListView to rebuild with new content before scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // First, try immediate scroll
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }

      // Then wait for ListView to rebuild and try again with _scrollToTop
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _scrollToTop();
        }
      });

      // One more attempt after longer delay to ensure it works
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    });
  }

  void _popToPreviousScreen() {
    // Since we're now updating chapters in-place instead of pushing new screens,
    // we only need to pop once to return to the bottom sheet
    if (!context.mounted) return;

    // Simply pop once to go back to previous screen (bottom sheet)
    if (Navigator.of(context).canPop()) {
      context.pop();
    }
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

        // Reload voice and language from preferences before using TTS
        // This ensures we use the latest settings even if changed in settings screen
        await _loadTTSVoice();

        // If voice is default (null), reset language to en-US
        final languageToUse = (_ttsVoice == null || _ttsVoice!.isEmpty)
            ? 'en-US'
            : _ttsLanguage;

        // Set language and voice from preferences
        try {
          await flutterTts.setLanguage(languageToUse);
        } catch (e) {
          try {
            // Fallback to language code without region
            final langCode = languageToUse.split('-')[0];
            await flutterTts.setLanguage(langCode);
          } catch (e2) {
            try {
              // Final fallback to en-US
              await flutterTts.setLanguage('en-US');
            } catch (e3) {
              print('Failed to set language: $e3');
            }
          }
        }

        // Set voice if available, otherwise use default voice
        if (_ttsVoice != null && _ttsVoice!.isNotEmpty) {
          try {
            // Find the correct locale for this voice
            final voiceLocale = _getVoiceLocale(_ttsVoice!);
            final localeToUse = voiceLocale ?? _ttsLanguage;

            await flutterTts.setVoice({
              'name': _ttsVoice!,
              'locale': localeToUse,
            });
            print('Voice set to: $_ttsVoice with locale: $localeToUse');
          } catch (e) {
            print('Failed to set voice: $e');
            // Continue without voice setting
          }
        } else {
          // When voice is null (default), use system default voice for English
          // Language is already set to en-US above when voice is default
          try {
            // Stop TTS first to ensure voice change takes effect
            await flutterTts.stop();
            // Small delay to ensure TTS is ready
            await Future.delayed(const Duration(milliseconds: 100));
            print('Voice reset to system default for language: $languageToUse');
          } catch (e) {
            print('Error resetting to default voice: $e');
            // Continue without voice setting, let system use default
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

  TextStyle _getTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
  }) {
    // Base size is 10, each increment adds 2
    final actualFontSize = fontSize + _fontSizeOffset;
    final fontFamilyName = _fontFamily == 'Default' ? null : _fontFamily;

    if (fontFamilyName == null) {
      return GoogleFonts.poppins(
        fontSize: actualFontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );
    }

    // Map font names to Google Fonts or system fonts
    // Note: System fonts (Times New Roman, Arial, etc.) are usually available on iOS/Android
    // For fonts that may not be available, we use Google Fonts or provide fallbacks
    switch (fontFamilyName) {
      case 'Times New Roman':
        // System font - usually available on iOS/Android
        return TextStyle(
          fontFamily: 'Times New Roman',
          fontSize: actualFontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontFamilyFallback: ['serif'], // Fallback to serif if not available
        );
      case 'Georgia':
        // System font - usually available on iOS/Android
        return TextStyle(
          fontFamily: 'Georgia',
          fontSize: actualFontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontFamilyFallback: ['serif'],
        );
      case 'Arial':
        // System font - usually available on iOS/Android
        return TextStyle(
          fontFamily: 'Arial',
          fontSize: actualFontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontFamilyFallback: ['sans-serif'],
        );
      case 'Verdana':
        // System font - usually available on iOS/Android
        return TextStyle(
          fontFamily: 'Verdana',
          fontSize: actualFontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontFamilyFallback: ['sans-serif'],
        );
      case 'Helvetica':
        // System font - usually available on iOS/Android
        return TextStyle(
          fontFamily: 'Helvetica',
          fontSize: actualFontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontFamilyFallback: ['sans-serif'],
        );
      case 'Open Dyslexic':
        // Not a system font - use Google Fonts or fallback
        // Note: OpenDyslexic may not be available in Google Fonts, so we use fallback
        return TextStyle(
          fontFamily: 'OpenDyslexic',
          fontSize: actualFontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontFamilyFallback: [
            'Arial',
            'sans-serif',
          ], // Fallback if font not available
        );
      case 'Garamond':
        // Use Google Fonts EB Garamond (similar to Garamond)
        return GoogleFonts.ebGaramond(
          fontSize: actualFontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
        );
      case 'Palatino':
        // System font - usually available on iOS/Android
        return TextStyle(
          fontFamily: 'Palatino',
          fontSize: actualFontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontFamilyFallback: ['serif'],
        );
      case 'Courier New':
        // System font - usually available on iOS/Android
        return TextStyle(
          fontFamily: 'Courier New',
          fontSize: actualFontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          fontFamilyFallback: ['monospace'],
        );
      default:
        return GoogleFonts.poppins(
          fontSize: actualFontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
        );
    }
  }

  Color _getBackgroundColor() {
    switch (_themeMode) {
      case 'Default':
        return Colors.black;
      case 'Light':
        return Colors.white;
      case 'Paper':
        return const Color(0xFFF5F5DC); // Beige
      case 'Calm':
        return const Color(0xFFE8F5E9); // Light green
      case 'Light blue':
        return const Color(0xFFE3F2FD); // Light blue
      default:
        return Colors.black;
    }
  }

  Color _getTextColor() {
    switch (_themeMode) {
      case 'Default':
        return Colors.white;
      case 'Light':
        return Colors.black;
      case 'Paper':
        return Colors.black87;
      case 'Calm':
        return Colors.black87;
      case 'Light blue':
        return Colors.black87;
      default:
        return Colors.white;
    }
  }

  Color _getFloatingActionButtonColor() {
    switch (_themeMode) {
      case 'Default':
        return Colors.grey.shade900;
      case 'Light':
        return Colors.grey.shade300;
      case 'Paper':
        return const Color(0xFFE8E8D0); // Slightly darker beige
      case 'Calm':
        return const Color(0xFFD4E5D6); // Slightly darker green
      case 'Light blue':
        return const Color(0xFFC5E1F5); // Slightly darker blue
      default:
        return Colors.grey.shade900;
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
    final backgroundColor = _getBackgroundColor();

    return Scaffold(
      backgroundColor: backgroundColor,
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
                    color: _getBackgroundColor(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Stack(
                      children: [
                        // Title centered - always full width, not affected by buttons
                        Positioned(
                          top: 50,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SizedBox(
                              width:
                                  MediaQuery.of(context).size.width -
                                  32 -
                                  96, // padding + space for buttons
                              child: Text(
                                _currentChapter.title,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _getTextColor(),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        // Pause button on the left (only show when playing)
                        if (_isPlaying)
                          Positioned(
                            top: 37,
                            left: 0,
                            child: IconButton(
                              icon: Icon(Icons.pause, color: _getTextColor()),
                              onPressed: _toggleSpeech,
                              iconSize: 24,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        // Close button aligned to right
                        Positioned(
                          top: 37,
                          right: 0,
                          child: IconButton(
                            icon: Icon(Icons.close, color: _getTextColor()),
                            onPressed: () => _popToPreviousScreen(),
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
                  backgroundColor: _getFloatingActionButtonColor(),
                  child: Image.asset(
                    "assets/icons/ic_feature.png",
                    width: 20,
                    height: 20,
                    color: _getTextColor().withValues(alpha: 0.9),
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
            fontSizeMultiplier: _fontSizeOffset,
            maxFontSizeMultiplier: _getMaxOffset(),
            fontFamily: _fontFamily,
            themeMode: _themeMode,
            onFontSizeChanged: (offset) {
              setState(() {
                _fontSizeOffset = offset;
              });
              setBottomSheetState(() {});
            },
            onFontFamilyChanged: (family) {
              setState(() {
                _fontFamily = family;
              });
              setBottomSheetState(() {});
            },
            onThemeModeChanged: (mode) {
              setState(() {
                _themeMode = mode;
              });
              setBottomSheetState(() {});
            },
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
      itemCount: _sentences.length + 1, // +1 for Next Chapter button
      itemBuilder: (context, index) {
        // Last item is the Next Chapter button
        if (index == _sentences.length) {
          return _buildNextChapterButton();
        }

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
            _getTextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: _getTextColor(),
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

  Widget _buildNextChapterButton() {
    final hasNextChapter = _currentChapterIndex < widget.allChapters.length - 1;
    final isLastChapter = _currentChapterIndex == widget.allChapters.length - 1;
    final isSingleChapter = widget.totalChapters == 1;

    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 32),
      child: Center(
        child: TextButton(
          onPressed: () {
            if (isSingleChapter || isLastChapter) {
              // Pop back to previous screen
              context.pop();
            } else if (hasNextChapter) {
              // Update to next chapter without pushing new screen
              final nextChapterIndex = _currentChapterIndex + 1;
              _updateChapter(nextChapterIndex);
            }
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: BorderSide(
                color: _getTextColor().withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          child: Text(
            isSingleChapter || isLastChapter
                ? 'That\'s it, let\'s explore other stories'
                : 'Next Chapter',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _getTextColor(),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
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
    // Get base text color from theme
    final baseColor = _getTextColor();

    // If not playing, use normal text color from theme
    // If playing: current sentence is full color, others are dimmed
    return Text(
      text,
      style: style.copyWith(
        color: isCurrent
            ? baseColor
            : (isDimmed ? baseColor.withValues(alpha: 0.4) : baseColor),
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
            style: _getTextStyle(
              fontSize: 10,
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
          style: _getTextStyle(
            fontSize: 10,
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
          style: _getTextStyle(
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
        style: _getTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: baseColor,
          height: 1.6,
        ),
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
  final int fontSizeMultiplier;
  final int maxFontSizeMultiplier;
  final String fontFamily;
  final String themeMode;
  final Function(int)? onFontSizeChanged;
  final Function(String)? onFontFamilyChanged;
  final Function(String)? onThemeModeChanged;

  const _StoryMenuBottomSheet({
    required this.chapterTitle,
    required this.chapterContent,
    required this.currentChapter,
    required this.totalChapters,
    required this.allChapters,
    required this.isPlaying,
    required this.workTitle,
    required this.fontSizeMultiplier,
    required this.maxFontSizeMultiplier,
    required this.fontFamily,
    required this.themeMode,
    this.onChapterTap,
    this.onPlayPauseTap,
    this.onFontSizeChanged,
    this.onFontFamilyChanged,
    this.onThemeModeChanged,
  });

  @override
  State<_StoryMenuBottomSheet> createState() => _StoryMenuBottomSheetState();
}

class _StoryMenuBottomSheetState extends State<_StoryMenuBottomSheet> {
  // TTS is handled by parent screen, bottom sheet just triggers it
  bool _showChaptersList = false;
  bool _showThemesList = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: _showChaptersList || _showThemesList
              ? screenHeight * 0.7
              : screenHeight * 0.4,
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
                          if (_showThemesList) {
                            _showThemesList = false;
                          }
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
                        setState(() {
                          if (_showChaptersList) {
                            _showChaptersList = false;
                          }
                          _showThemesList = !_showThemesList;
                        });
                      },
                    ),
                    // Themes section (shown when _showThemesList is true)
                    if (_showThemesList) ...[
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 16),
                      // Font Size Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Decrease button
                          GestureDetector(
                            onTap:
                                widget.fontSizeMultiplier > 0 &&
                                    widget.onFontSizeChanged != null
                                ? () {
                                    widget.onFontSizeChanged!(
                                      widget.fontSizeMultiplier - 2,
                                    );
                                  }
                                : null,
                            child: Container(
                              width: 150,
                              height: 40,
                              decoration: BoxDecoration(
                                color: widget.fontSizeMultiplier > 0
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: widget.fontSizeMultiplier > 0
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'A-',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: widget.fontSizeMultiplier > 0
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Increase button
                          GestureDetector(
                            onTap:
                                widget.fontSizeMultiplier <
                                        widget.maxFontSizeMultiplier &&
                                    widget.onFontSizeChanged != null
                                ? () {
                                    widget.onFontSizeChanged!(
                                      widget.fontSizeMultiplier + 2,
                                    );
                                  }
                                : null,
                            child: Container(
                              width: 150,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    widget.fontSizeMultiplier <
                                        widget.maxFontSizeMultiplier
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                border: Border.all(
                                  color:
                                      widget.fontSizeMultiplier <
                                          widget.maxFontSizeMultiplier
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'A+',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        widget.fontSizeMultiplier <
                                            widget.maxFontSizeMultiplier
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Font Family Selection
                      Text(
                        'Default Font',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children:
                              [
                                'Default',
                                'Times New Roman',
                                'Georgia',
                                'Arial',
                                'Verdana',
                                'Helvetica',
                                'Open Dyslexic',
                                'Garamond',
                                'Palatino',
                                'Courier New',
                              ].map((font) {
                                final isSelected = widget.fontFamily == font;
                                return GestureDetector(
                                  onTap: widget.onFontFamilyChanged != null
                                      ? () {
                                          widget.onFontFamilyChanged!(font);
                                        }
                                      : null,
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white.withValues(
                                                alpha: 0.3,
                                              ),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Center(
                                      child: Text(
                                        font,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white.withValues(
                                                  alpha: 0.7,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Theme Mode Selection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children:
                            [
                              {'name': 'Default', 'color': Colors.black},
                              {
                                'name': 'Light',
                                'color': const Color(0xFFfefefe),
                              },
                              {
                                'name': 'Paper',
                                'color': const Color(0xFF1d1d1d),
                              },
                              {
                                'name': 'Calm',
                                'color': const Color(0xFF3b392c),
                              },
                              {
                                'name': 'Blue',
                                'color': const Color(0xFF3f4b71),
                              },
                            ].map((theme) {
                              final themeName = theme['name'] as String;
                              final isSelected =
                                  widget.themeMode == themeName ||
                                  (themeName == 'Blue' &&
                                      widget.themeMode == 'Light blue');
                              final themeColor = theme['color'] as Color;
                              return GestureDetector(
                                onTap: widget.onThemeModeChanged != null
                                    ? () {
                                        // Map 'Blue' to 'Light blue' for compatibility
                                        final themeToSet = themeName == 'Blue'
                                            ? 'Light blue'
                                            : themeName;
                                        widget.onThemeModeChanged!(themeToSet);
                                      }
                                    : null,
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: themeColor,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF7d26cd)
                                          : Colors.white.withOpacity(0.1),
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(360),
                                  ),
                                  child: Center(
                                    child: Text(
                                      themeName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: themeName == 'Light'
                                            ? const Color(0xFF121212)
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getThemeColor(String theme) {
    switch (theme) {
      case 'Default':
        return const Color(0xFF121212); // Dark background
      case 'Light':
        return const Color(0xFFFFFFFF); // White
      case 'Paper':
        return const Color(0xFFF5F5DC); // Beige/Paper color
      case 'Calm':
        return const Color(0xFFE8F5E9); // Light green/Calm
      case 'Light blue':
        return const Color(0xFFE3F2FD); // Light blue
      default:
        return const Color(0xFF121212);
    }
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
