import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../repositories/category_repository.dart';
import '../services/fandom_service.dart';
import '../services/search_service.dart';
import '../services/saved_works_service.dart';
import '../services/work_service.dart';
import '../models/fandom_model.dart';
import '../models/category_model.dart';
import '../models/work_model.dart';
import '../widgets/loading_indicator.dart';

class ChatBotSuggestionScreen extends StatefulWidget {
  const ChatBotSuggestionScreen({super.key});

  @override
  State<ChatBotSuggestionScreen> createState() =>
      _ChatBotSuggestionScreenState();
}

enum ChatMessageType { user, bot }

class ChatMessage {
  final ChatMessageType type;
  final String text;
  final List<FandomModel>? fandoms;
  final List<WorkModel>? works;

  ChatMessage({
    required this.type,
    required this.text,
    this.fandoms,
    this.works,
  });
}

class _ChatBotSuggestionScreenState extends State<ChatBotSuggestionScreen> {
  final CategoryRepository _categoryRepository = CategoryRepository();
  final FandomService _fandomService = FandomService();
  final SearchService _searchService = SearchService();
  final SavedWorksService _savedWorksService = SavedWorksService();
  final WorkService _workService = WorkService();
  final ScrollController _scrollController = ScrollController();
  bool _isYesSelected = false;
  bool _isNoSelected = false;
  bool _isButtonsDisabled = false;
  bool _isLoadingCategories = false;
  List<ChatMessage> _chatMessages = [];
  bool _isLoadingFandoms = false;
  String? _selectedCategoryId;
  final TextEditingController _messageController = TextEditingController();
  final Set<String> _savingWorkIds = {}; // Track works being saved

  bool get _hasFandomMessage {
    return _chatMessages.any(
      (message) =>
          message.type == ChatMessageType.bot &&
          (message.fandoms != null || message.works != null),
    );
  }

  /// Filter out fandoms that contain arrow characters
  List<FandomModel> _filterFandomsWithArrows(List<FandomModel> fandoms) {
    // Common arrow characters (Unicode ranges)
    final arrowPattern = RegExp(
      r'[\u2190-\u2199\u21A0-\u21A9\u21B0-\u21B9\u21D0-\u21D9\u21E0-\u21E9\u2B00-\u2BFF\u27A0-\u27BF]',
    );
    return fandoms
        .where((fandom) => !arrowPattern.hasMatch(fandom.name))
        .toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _scrollToBottom() async {
    // Wait for the widget to rebuild with categories
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 200));
      if (_scrollController.hasClients && mounted) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleYesTap() async {
    if (_isButtonsDisabled) return;

    setState(() {
      _isYesSelected = true;
      _isNoSelected = false;
      _isButtonsDisabled = true;
      _isLoadingCategories = true;
    });

    // Load categories from repository
    await _categoryRepository.loadCategories();

    if (mounted) {
      setState(() {
        _isLoadingCategories = false;
      });
      // Scroll to bottom after categories are loaded
      _scrollToBottom();
    }
  }

  void _handleNoTap() {
    if (_isButtonsDisabled) return;

    setState(() {
      _isNoSelected = true;
      _isYesSelected = false;
      _isButtonsDisabled = true;
    });
  }

  Future<void> _handleCategoryTap(CategoryModel category) async {
    if (_isLoadingFandoms) return;

    // Set selected category
    setState(() {
      _selectedCategoryId = category.id;
    });

    // Add user message
    setState(() {
      _chatMessages.add(
        ChatMessage(
          type: ChatMessageType.user,
          text: "I'm into ${category.name}",
        ),
      );
      _isLoadingFandoms = true;
    });

    // Scroll to show user message
    _scrollToBottom();

    try {
      // Get fandoms for this category
      final fandoms = await _fandomService.getFandomsByCategory(category.id);

      // Filter out fandoms with arrow characters
      final filteredFandoms = _filterFandomsWithArrows(fandoms);

      // Take first 3 fandoms as examples
      final exampleFandoms = filteredFandoms.take(3).toList();

      if (mounted) {
        setState(() {
          // Add bot response with fandoms
          _chatMessages.add(
            ChatMessage(
              type: ChatMessageType.bot,
              text:
                  "Cool, what are your favorite ${category.name.toLowerCase()} fandoms?",
              fandoms: exampleFandoms,
            ),
          );
          _isLoadingFandoms = false;
        });
        // Scroll to show bot response
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatMessages.add(
            ChatMessage(
              type: ChatMessageType.bot,
              text: "Sorry, I couldn't load fandoms for this category.",
            ),
          );
          _isLoadingFandoms = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoadingFandoms) return;

    // Clear text field
    _messageController.clear();

    // Add user message
    setState(() {
      _chatMessages.add(
        ChatMessage(type: ChatMessageType.user, text: text.toLowerCase()),
      );
      _isLoadingFandoms = true;
    });

    // Scroll to show user message
    _scrollToBottom();

    try {
      // Call search API to find works (same as search_screen.dart)
      final searchResponse = await _searchService.searchWorks(text, page: 1);

      if (mounted) {
        setState(() {
          // Add bot response with works
          _chatMessages.add(
            ChatMessage(
              type: ChatMessageType.bot,
              text: searchResponse.works.isNotEmpty
                  ? "Here are some stories I found for you:"
                  : "Sorry, I couldn't find any stories for that search.",
              works: searchResponse.works.isNotEmpty
                  ? searchResponse.works.take(10).toList()
                  : null,
            ),
          );
          _isLoadingFandoms = false;
        });
        // Scroll to show bot response
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatMessages.add(
            ChatMessage(
              type: ChatMessageType.bot,
              text: "Sorry, I couldn't find any stories for that search.",
            ),
          );
          _isLoadingFandoms = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _handleFandomTap(FandomModel fandom) async {
    if (_isLoadingFandoms) return;

    // Add user message
    setState(() {
      _chatMessages.add(
        ChatMessage(type: ChatMessageType.user, text: fandom.name),
      );
      _isLoadingFandoms = true;
    });

    // Scroll to show user message
    _scrollToBottom();

    try {
      // Get works for this fandom
      final works = await _workService.getWorksByFandom(fandom.id);

      if (mounted) {
        setState(() {
          // Add bot response with works
          _chatMessages.add(
            ChatMessage(
              type: ChatMessageType.bot,
              text: works.isNotEmpty
                  ? "Here are some stories from ${fandom.name}:"
                  : "Sorry, I couldn't find any stories for ${fandom.name}.",
              works: works.isNotEmpty ? works.take(10).toList() : null,
            ),
          );
          _isLoadingFandoms = false;
        });
        // Scroll to show bot response
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatMessages.add(
            ChatMessage(
              type: ChatMessageType.bot,
              text: "Sorry, I couldn't load stories for ${fandom.name}.",
            ),
          );
          _isLoadingFandoms = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _handleNoneOfThem() async {
    // Add bot message
    setState(() {
      _chatMessages.add(
        ChatMessage(
          type: ChatMessageType.bot,
          text: "See you, I'll be right here if you need me.",
        ),
      );
    });

    // Scroll to show message
    _scrollToBottom();

    // Wait 1.5 seconds then pop
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _handleWorkSelection(WorkModel work) async {
    // Check if already saving
    if (_savingWorkIds.contains(work.id)) return;

    // Add to saving set
    setState(() {
      _savingWorkIds.add(work.id);
    });

    try {
      // Save work to library
      print('💾 Saving work to library: ${work.id} - ${work.title}');
      final success = await _savedWorksService.saveWork(work);
      print('💾 Save result: $success');

      // Verify the work was saved
      final isSaved = await _savedWorksService.isWorkSaved(work.id);
      print('💾 Work is saved: $isSaved');

      if (mounted) {
        // Show SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Story added to library'
                  : 'Failed to add story to library',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
            ),
            backgroundColor: success ? const Color(0xFF7d26cd) : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );

        // Add bot message with confirmation and question
        if (success) {
          setState(() {
            _chatMessages.add(
              ChatMessage(
                type: ChatMessageType.bot,
                text:
                    "Great! I've saved \"${work.title}\" to your library. Would you like to find another story?",
              ),
            );
          });
          // Scroll to show bot message
          _scrollToBottom();
        }
      }
    } finally {
      // Remove from saving set
      if (mounted) {
        setState(() {
          _savingWorkIds.remove(work.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121212),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: _hasFandomMessage ? 80 : 15,
                    ),
                    child: Column(
                      children: [
                        // Spacer to push content to bottom initially
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                        ),
                        // Robot Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7d26cd),
                            border: Border.all(
                              color: const Color(0xFF37393f),
                              width: 0.6,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/images/img_book.svg',
                              width: 78,
                              height: 65,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 66),
                        // Message Bubbles
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // First message bubble
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7d26cd),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  'Hiya, and welcome to Fanfiction AO3 Reader',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Second message bubble with options
                              Container(
                                width: 335,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7d26cd),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'I can help you find some good stories 😊. Would you like to continue?',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    // Divider
                                    Container(
                                      height: 1,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 15),
                                    // Yes option
                                    GestureDetector(
                                      onTap: _isButtonsDisabled
                                          ? null
                                          : _handleYesTap,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          'Yes',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: _isNoSelected
                                                ? Colors.grey
                                                : Colors.white,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    // Divider
                                    Container(
                                      height: 1,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 15),
                                    // No option
                                    GestureDetector(
                                      onTap: _isButtonsDisabled
                                          ? null
                                          : _handleNoTap,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          'No',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: _isYesSelected
                                                ? Colors.grey
                                                : Colors.white,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Categories section (shown after Yes is selected)
                        if (_isYesSelected) ...[
                          const SizedBox(height: 15),
                          _buildCategoriesSection(),
                        ],
                        // Chat messages section
                        if (_chatMessages.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          ..._chatMessages.map(
                            (message) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildChatMessage(message),
                            ),
                          ),
                        ],
                        // Loading indicator for fandoms
                        if (_isLoadingFandoms) ...[
                          const SizedBox(height: 16),
                          const Center(
                            child: LoadingIndicator(color: Color(0xFF7d26cd)),
                          ),
                        ],
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Close button at top right
            Positioned(
              top: 0,
              right: 20,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () {
                    context.pop();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
            // Input field and send button at bottom
            if (_hasFandomMessage)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    color: const Color(0xFF121212),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Text field
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF343A40),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: TextField(
                              controller: _messageController,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Type your response...',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Send button
                        GestureDetector(
                          onTap: () => _handleSendMessage(),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.send,
                              color: const Color(0xFFA0A0A0),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    if (_isLoadingCategories) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: LoadingIndicator(color: Color(0xFF7d26cd)),
        ),
      );
    }

    if (_categoryRepository.error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Error loading categories: ${_categoryRepository.error}',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final categories = _categoryRepository.categories;
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'No categories available',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 335,
        decoration: BoxDecoration(
          color: const Color(0xFF7d26cd),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'What types of fan fiction are you into?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            // Divider after title
            Container(height: 1, color: Colors.white.withOpacity(0.3)),
            // Categories list
            ...categories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              return Column(
                children: [
                  // Category item
                  InkWell(
                    onTap: () => _handleCategoryTap(category),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              category.name,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color:
                                    _selectedCategoryId == null ||
                                        _selectedCategoryId == category.id
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Divider (except for last item)
                  if (index < categories.length - 1)
                    Container(height: 1, color: Colors.white.withOpacity(0.3)),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    if (message.type == ChatMessageType.user) {
      // User message - right side, pink/magenta color
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE91E63), // Pink/magenta
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
          ),
          child: Text(
            message.text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else {
      // Bot message - left side, purple color
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF7d26cd),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              if (message.fandoms != null && message.fandoms!.isNotEmpty) ...[
                const SizedBox(height: 12),
                // Fandom options
                ...message.fandoms!.map((fandom) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _handleFandomTap(fandom),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B1FA6), // Darker purple
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          fandom.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 8),
                // "None of them" option
                InkWell(
                  onTap: _handleNoneOfThem,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B1FA6), // Darker purple
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'None of them',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '(Type your response below ⌨️)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
              if (message.works != null && message.works!.isNotEmpty) ...[
                const SizedBox(height: 12),
                // Work options
                ...message.works!.map((work) {
                  final isSaving = _savingWorkIds.contains(work.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: isSaving ? null : () => _handleWorkSelection(work),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSaving
                              ? const Color(0xFF6B1FA6).withOpacity(0.6)
                              : const Color(0xFF6B1FA6), // Darker purple
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    work.title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSaving
                                          ? Colors.white.withOpacity(0.7)
                                          : Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (work.author.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      work.author,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: isSaving
                                            ? Colors.white.withOpacity(0.5)
                                            : Colors.white.withOpacity(0.7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSaving) ...[
                              const SizedBox(width: 12),
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      );
    }
  }
}
