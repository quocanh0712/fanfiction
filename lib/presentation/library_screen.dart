import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_header.dart';
import '../services/saved_works_service.dart';
import '../models/work_model.dart';
import '../widgets/work_item.dart';
import '../widgets/loading_indicator.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final SavedWorksService _savedWorksService = SavedWorksService();
  List<WorkModel> _savedWorks = [];
  List<WorkModel> _filteredWorks = [];
  bool _isLoading = true;
  final Map<String, bool> _expandedTags = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSavedWorks(isInitialLoad: true);
  }

  Future<void> _loadSavedWorks({bool isInitialLoad = false}) async {
    if (isInitialLoad) {
      setState(() {
        _isLoading = true;
      });
    }
    // Note: RefreshIndicator automatically shows loading indicator during refresh

    try {
      final savedWorks = await _savedWorksService.getSavedWorks();
      if (mounted) {
        setState(() {
          _savedWorks = savedWorks;
          _filteredWorks = savedWorks;
          _isLoading = false;
        });
        _filterWorks(_searchQuery);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterWorks(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredWorks = _savedWorks;
      } else {
        final lowerQuery = query.toLowerCase().trim();
        _filteredWorks = _savedWorks.where((work) {
          // Search by title
          if (work.title.toLowerCase().contains(lowerQuery)) {
            return true;
          }
          // Search by author
          if (work.author.toLowerCase().contains(lowerQuery)) {
            return true;
          }
          // Search by tags
          if (work.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))) {
            return true;
          }
          return false;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color(0xFF121212),
      child: Column(
        children: [
          AppHeader(
            onSearchChanged: _filterWorks,
            searchHint: 'Search works, tags...',
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: LoadingIndicator(color: Color(0xFF7d26cd)),
                  )
                : _filteredWorks.isEmpty
                ? _buildEmptyState()
                : _buildSavedWorksList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            "assets/images/img_newspaper_home.png",
            width: 84,
            height: 64,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Read Story',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Alone in this space',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Store stories in your library to view later.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Search Stories',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedWorksList() {
    return RefreshIndicator(
      onRefresh: () => _loadSavedWorks(isInitialLoad: false),
      color: const Color(0xFF7d26cd),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _filteredWorks.length,
        separatorBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(left: 16),
          child: const Divider(
            color: Color(0xFF2A2A2A),
            thickness: 1,
            height: 1,
          ),
        ),
        itemBuilder: (context, index) {
          final work = _filteredWorks[index];
          return WorkItem(
            work: work,
            expandedTags: _expandedTags,
            onTagExpanded: (workId) {
              setState(() {
                _expandedTags[workId] = !(_expandedTags[workId] ?? false);
              });
            },
            onWorkTap: () async {
              // Reload saved works after potential unsave
              await Future.delayed(const Duration(milliseconds: 300));
              _loadSavedWorks(isInitialLoad: false);
            },
          );
        },
      ),
    );
  }
}
