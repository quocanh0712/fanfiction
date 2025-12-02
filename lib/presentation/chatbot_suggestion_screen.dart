import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../repositories/category_repository.dart';
import '../widgets/loading_indicator.dart';

class ChatBotSuggestionScreen extends StatefulWidget {
  const ChatBotSuggestionScreen({super.key});

  @override
  State<ChatBotSuggestionScreen> createState() =>
      _ChatBotSuggestionScreenState();
}

class _ChatBotSuggestionScreenState extends State<ChatBotSuggestionScreen> {
  final CategoryRepository _categoryRepository = CategoryRepository();
  final ScrollController _scrollController = ScrollController();
  bool _isYesSelected = false;
  bool _isNoSelected = false;
  bool _isButtonsDisabled = false;
  bool _isLoadingCategories = false;

  @override
  void dispose() {
    _scrollController.dispose();
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    onTap: () {
                      // Handle category tap if needed
                    },
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
                                color: Colors.white,
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
}
