import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/work_service.dart';
import '../models/work_model.dart';
import '../widgets/sticky_header.dart';

class WorkScreen extends StatefulWidget {
  final String categoryName;
  final String fandomName;
  final String fandomId;
  final int storyCount;

  const WorkScreen({
    super.key,
    required this.categoryName,
    required this.fandomName,
    required this.fandomId,
    required this.storyCount,
  });

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {
  final WorkService _workService = WorkService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, bool> _expandedTags =
      {}; // Track expanded state for each work
  List<WorkModel> _works = [];
  List<WorkModel> _filteredWorks = [];
  bool _isLoading = false;
  String? _error;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadWorks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredWorks = _works;
      } else {
        _filteredWorks = _works
            .where(
              (work) =>
                  work.title.toLowerCase().contains(query) ||
                  work.author.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  String _formatStoryCount(int count) {
    if (count >= 1000) {
      final kCount = (count / 1000).floor();
      return '${kCount}k stories';
    }
    return '$count stories';
  }

  Future<void> _loadWorks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final works = await _workService.getWorksByFandom(widget.fandomId);
      setState(() {
        _works = works;
        _filteredWorks = works;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color(0xFF121212),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            const SizedBox(height: 50),
            StickyHeader(
              title: widget.fandomName,
              backButtonText: widget.categoryName,
              scrollOffset: _scrollOffset,
              onBackTap: () => context.pop(),
              searchBar: _buildSearchBar(),
            ),
            const SizedBox(height: 5),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white70, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    cursorColor: Colors.white,
                    controller: _searchController,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                    },
                    child: const Icon(
                      Icons.clear,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              _formatStoryCount(widget.storyCount),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7d26cd)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Error loading works',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    if (_filteredWorks.isEmpty) {
      return Center(
        child: Text(
          'No works available',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: _filteredWorks.length,
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(left: 16),
        child: const Divider(color: Color(0xFF2A2A2A), thickness: 1, height: 1),
      ),
      itemBuilder: (context, index) {
        return _buildWorkItem(_filteredWorks[index]);
      },
    );
  }

  Widget _buildWorkItem(WorkModel work) {
    return InkWell(
      onTap: () {
        // Navigate to work details
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              work.title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Tags
            if (work.tags.isNotEmpty) _buildTagsSection(work),
            if (work.tags.isNotEmpty) const SizedBox(height: 12),
            // Summary
            Text(
              work.summary,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.9),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Stats
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (work.stats.language != null)
                  _buildPillTag(work.stats.language!),
                if (work.stats.chapters != null)
                  _buildPillTag(work.stats.chapters!),
                if (work.stats.words != null) _buildPillTag(work.stats.words!),
                if (work.stats.collections != null)
                  _buildPillTag(work.stats.collections!),
                if (work.stats.comments != null)
                  _buildPillTag(work.stats.comments!),
                if (work.stats.kudos != null) _buildPillTag(work.stats.kudos!),
                if (work.stats.hits != null) _buildPillTag(work.stats.hits!),
                if (work.stats.bookmarks != null)
                  _buildPillTag(work.stats.bookmarks!),
              ],
            ),
            const SizedBox(height: 8),
            // Author
            Row(
              children: [
                Text(
                  'by',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                SizedBox(width: 5),
                Text(
                  work.author,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(WorkModel work) {
    final isExpanded = _expandedTags[work.id] ?? false;
    final tagsCount = work.tags.length;

    if (tagsCount <= 1) {
      // Chỉ có 1 tag hoặc ít hơn, hiển thị trực tiếp
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: work.tags.map((tag) => _buildPillTag(tag)).toList(),
      );
    }

    // Nhiều hơn 1 tag, hiển thị expandable với animation
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: isExpanded
            ? [
                // Đã mở rộng: hiển thị tất cả tags + nút collapse
                ...work.tags.map((tag) => _buildPillTag(tag)),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _expandedTags[work.id] = false;
                    });
                  },
                  child: _buildPillTag('Show less'),
                ),
              ]
            : [
                // Chưa mở rộng: hiển thị tag đầu tiên + nút "and X more"
                _buildPillTag(work.tags[0]),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _expandedTags[work.id] = true;
                    });
                  },
                  child: _buildPillTag('and ${tagsCount - 1} more...'),
                ),
              ],
      ),
    );
  }

  Widget _buildPillTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}
