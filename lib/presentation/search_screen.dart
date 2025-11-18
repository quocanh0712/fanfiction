import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_header.dart';
import '../repositories/category_repository.dart';
import '../models/category_model.dart';
import '../models/work_model.dart';
import '../services/search_service.dart';
import '../widgets/work_item.dart';
import '../widgets/loading_indicator.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final CategoryRepository _categoryRepository = CategoryRepository();
  final SearchService _searchService = SearchService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  List<WorkModel> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMorePages = false;
  int _totalResults = 0;
  String? _error;
  final Map<String, bool> _expandedTags = {};
  String _lastSearchQuery =
      ''; // Track last search query to prevent duplicate calls

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    await _categoryRepository.loadCategories();
    if (mounted) {
      setState(() {});
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    // Cancel previous timer
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      // Clear results when query is empty
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _currentPage = 1;
        _hasMorePages = false;
        _totalResults = 0;
        _lastSearchQuery = '';
      });
      return;
    }

    // Only search if query actually changed (not just focus)
    if (query == _lastSearchQuery) {
      return;
    }

    // Debounce search API call
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      // Double check query hasn't changed during debounce
      final currentQuery = _searchController.text.trim();
      if (currentQuery.isNotEmpty && currentQuery != _lastSearchQuery) {
        _performSearch(currentQuery, page: 1);
      }
    });
  }

  Future<void> _performSearch(String query, {int page = 1}) async {
    if (query.isEmpty) return;

    setState(() {
      if (page == 1) {
        _isSearching = true;
        _searchResults = [];
        _currentPage = 1;
        _totalResults = 0;
      } else {
        _isLoadingMore = true;
      }
      _error = null;
    });

    try {
      final response = await _searchService.searchWorks(query, page: page);

      if (mounted) {
        setState(() {
          if (page == 1) {
            _searchResults = response.works;
            _totalResults = response.totalResults;
            _lastSearchQuery = query; // Update last search query
          } else {
            _searchResults.addAll(response.works);
          }
          _currentPage = response.page;
          _hasMorePages = response.hasMorePages;
          _isSearching = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSearching = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    // Only check scroll position if we have valid scroll metrics
    if (!_scrollController.hasClients) return;

    // Load more when scrolling near bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final query = _searchController.text.trim();
      if (!_isLoadingMore &&
          _hasMorePages &&
          query.isNotEmpty &&
          query == _lastSearchQuery) {
        // Only load more if query matches last search
        _performSearch(query, page: _currentPage + 1);
      }
    }
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _debounceTimer?.cancel();
      _performSearch(query, page: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSearchQuery = _searchController.text.trim().isNotEmpty;

    return Material(
      color: const Color(0xFF121212),
      child: Column(
        children: [
          const AppHeader(title: 'Search', isHaveIcon: false),
          // Animated search input - moves to top when has query
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, -0.3),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: hasSearchQuery
                ? Padding(
                    key: const ValueKey('search-input-top'),
                    padding: const EdgeInsets.fromLTRB(20,16,20,10

                    ),
                    child: _buildSearchInput(),
                  )
                : const SizedBox.shrink(key: ValueKey('search-input-hidden')),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          ),
                        ),
                    child: child,
                  ),
                );
              },
              child: hasSearchQuery
                  ? _buildSearchResults(key: const ValueKey('search-results'))
                  : _buildInitialContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialContent() {
    return LayoutBuilder(
      key: const ValueKey('initial-content'),
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
                  // Search Input Section - in the middle when no query
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: _buildSearchInput(),
                  ),
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

  Widget _buildSearchResults({Key? key}) {
    Widget content;

    if (_isSearching && _searchResults.isEmpty) {
      content = const Center(child: LoadingIndicator(color: Color(0xFF7d26cd)));
    } else if (_error != null && _searchResults.isEmpty) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading results',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else if (_searchResults.isEmpty) {
      content = Center(
        child: Text(
          'No results found',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      );
    } else {
      content = Column(
        children: [
          // Results count - above search results
          if (_totalResults > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _buildResultsCount(),
            ),
          // Search results list
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              itemCount: _searchResults.length + (_isLoadingMore ? 1 : 0),
              separatorBuilder: (context, index) {
                if (index >= _searchResults.length)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: const Divider(
                    color: Color(0xFF2A2A2A),
                    thickness: 1,
                    height: 1,
                  ),
                );
              },
              itemBuilder: (context, index) {
                if (index >= _searchResults.length) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: LoadingIndicator(color: Color(0xFF7d26cd)),
                    ),
                  );
                }

                final work = _searchResults[index];
                return WorkItem(
                  work: work,
                  expandedTags: _expandedTags,
                  onTagExpanded: (workId) {
                    setState(() {
                      _expandedTags[workId] = !(_expandedTags[workId] ?? false);
                    });
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    return SizedBox(key: key, child: content);
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
    final hasSearchQuery = _searchController.text.trim().isNotEmpty;

    return Container(
      key: ValueKey('search-input-${hasSearchQuery ? 'top' : 'center'}'),
      width: hasSearchQuery
          ? double.infinity
          : MediaQuery.of(context).size.width * 0.8,
      alignment: hasSearchQuery ? Alignment.centerLeft : Alignment.center,
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

  Widget _buildResultsCount() {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, -0.2),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
              child: child,
            ),
          );
        },
        child: Text(
          _formatResultsCount(_totalResults),
          key: ValueKey('results-count-$_totalResults'),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  String _formatResultsCount(int count) {
    if (count == 0) return 'No stories found';
    if (count == 1) return '1 story';

    // Format large numbers
    if (count >= 1000000) {
      final millions = count / 1000000;
      if (millions % 1 == 0) {
        return '${millions.toInt()}M stories';
      }
      return '${millions.toStringAsFixed(1)}M stories';
    } else if (count >= 1000) {
      final thousands = count / 1000;
      if (thousands % 1 == 0) {
        return '${thousands.toInt()}K stories';
      }
      return '${thousands.toStringAsFixed(1)}K stories';
    }

    return '$count stories';
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
