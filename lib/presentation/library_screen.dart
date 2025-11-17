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
  bool _isLoading = true;
  final Map<String, bool> _expandedTags = {};

  @override
  void initState() {
    super.initState();
    _loadSavedWorks();
  }

  Future<void> _loadSavedWorks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final savedWorks = await _savedWorksService.getSavedWorks();
      if (mounted) {
        setState(() {
          _savedWorks = savedWorks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color(0xFF121212),
      child: Column(
        children: [
          const AppHeader(),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: LoadingIndicator(color: Color(0xFF7d26cd)),
                  )
                : _savedWorks.isEmpty
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
      onRefresh: _loadSavedWorks,
      color: const Color(0xFF7d26cd),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: _savedWorks.length,
        separatorBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(left: 16),
          child: const Divider(
            color: Color(0xFF2A2A2A),
            thickness: 1,
            height: 1,
          ),
        ),
        itemBuilder: (context, index) {
          final work = _savedWorks[index];
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
              _loadSavedWorks();
            },
          );
        },
      ),
    );
  }
}
