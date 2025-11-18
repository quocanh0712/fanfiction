import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_header.dart';
import '../repositories/category_repository.dart';
import '../models/category_model.dart';
import '../widgets/loading_indicator.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final CategoryRepository _categoryRepository = CategoryRepository();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    await _categoryRepository.loadCategories();
    if (mounted) {
      setState(() {});
    }
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      // TODO: Implement search functionality
      print('Search query: $query');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121212),
      child: Column(
        children: [
          const AppHeader(title: 'Search', isHaveIcon: false),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Search Prompt Section
                  _buildSearchPrompt(),
                  const SizedBox(height: 60),
                  // Search Input Section
                  _buildSearchInput(),
                  const SizedBox(height: 60),
                  // Category Chips Section
                  _buildCategoryChips(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchPrompt() {
    return Column(
      children: [
        Text(
          'Search for something',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Or try our AI-powered recommendations',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSearchInput() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          // Underline decoration
          Positioned(
            left: 0,
            right: 50,
            bottom: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7d26cd).withOpacity(0.3),
                    const Color(0xFF7d26cd),
                  ],
                ),
              ),
            ),
          ),
          // TextField
          TextField(
            controller: _searchController,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
            cursorColor: const Color(0xFF7d26cd),
            decoration: InputDecoration(
              hintText: 'Search Stories',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.only(bottom: 10, right: 50),
            ),
            onSubmitted: (_) => _onSearch(),
          ),
          // Search Button
          Positioned(
            right: 0,
            child: GestureDetector(
              onTap: _onSearch,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF7d26cd),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search, size: 24, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    if (_categoryRepository.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: LoadingIndicator(color: Color(0xFF7d26cd)),
        ),
      );
    }

    final categories = _categoryRepository.categories;
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    // Only show first 5 categories
    final displayedCategories = categories.take(5).toList();

    // Split into rows (first 3, then remaining 2)
    final firstRowCategories = displayedCategories.take(3).toList();
    final secondRowCategories = displayedCategories.skip(3).toList();

    return Column(
      children: [
        // First Row
        if (firstRowCategories.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 15,
            alignment: WrapAlignment.start,
            children: firstRowCategories
                .map((category) => _buildCategoryChip(category))
                .toList(),
          ),
        // Second Row
        if (secondRowCategories.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 15,
            alignment: WrapAlignment.center,
            children: secondRowCategories
                .map((category) => _buildCategoryChip(category))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryChip(CategoryModel category) {
    return GestureDetector(
      onTap: () {
        context.push(
          '/home/category/fandom?categoryId=${category.id}&categoryName=${Uri.encodeComponent(category.name)}',
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 1),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                category.name,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
