import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/fandom_service.dart';
import '../models/fandom_model.dart';
import '../widgets/sticky_header.dart';

class FandomScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const FandomScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<FandomScreen> createState() => _FandomScreenState();
}

class _FandomScreenState extends State<FandomScreen> {
  final FandomService _fandomService = FandomService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<FandomModel> _fandoms = [];
  List<FandomModel> _filteredFandoms = [];
  bool _isLoading = false;
  String? _error;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadFandoms();
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
        _filteredFandoms = _fandoms;
      } else {
        _filteredFandoms = _fandoms
            .where((fandom) => fandom.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _loadFandoms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fandoms = await _fandomService.getFandomsByCategory(
        widget.categoryId,
      );
      setState(() {
        _fandoms = fandoms;
        _filteredFandoms = fandoms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatStoryCount(int? count) {
    if (count == null) return '0 stories';
    if (count >= 1000) {
      final kCount = (count / 1000).floor();
      return '${kCount}k stories';
    }
    return '$count stories';
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
            SizedBox(height: 50),
            StickyHeader(
              title: widget.categoryName,
              backButtonText: 'Categories',
              scrollOffset: _scrollOffset,
              onBackTap: () => context.pop(),
              searchBar: _buildSearchBar(),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.grey.shade600,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(CupertinoIcons.search, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                cursorColor: Colors.white,
                controller: _searchController,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
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
                  CupertinoIcons.clear_circled_solid,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
          ],
        ),
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
            'Error loading fandoms',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    if (_filteredFandoms.isEmpty) {
      return Center(
        child: Text(
          'No fandoms available',
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
      itemCount: _filteredFandoms.length,
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(left: 16),
        child: const Divider(color: Color(0xFF2A2A2A), thickness: 1, height: 1),
      ),
      itemBuilder: (context, index) {
        return _buildFandomItem(_filteredFandoms[index]);
      },
    );
  }

  Widget _buildFandomItem(FandomModel fandom) {
    return InkWell(
      onTap: () {
        context.push(
          '/home/category/fandom/work?categoryName=${Uri.encodeComponent(widget.categoryName)}&fandomName=${Uri.encodeComponent(fandom.name)}&fandomId=${Uri.encodeComponent(fandom.id)}&storyCount=${fandom.count ?? 0}',
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Story count
            Text(
              _formatStoryCount(fandom.count),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            // Fandom name
            Text(
              fandom.name,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
