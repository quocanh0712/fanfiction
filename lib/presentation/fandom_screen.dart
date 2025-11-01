import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/fandom_service.dart';
import '../models/fandom_model.dart';

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

  bool _showSearchBar() {
    return _scrollOffset < 50;
  }

  bool _showBigTitle() {
    return _scrollOffset < 150;
  }

  bool _showSmallTitle() {
    return _scrollOffset >= 150;
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
            _buildHeader(),
            if (_showSearchBar()) ...[
              const SizedBox(height: 5),
              _buildSearchBar(),
            ],
            const SizedBox(height: 10),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stack để title có thể nằm chính giữa màn hình
          Stack(
            alignment: Alignment.center,
            children: [
              // Back button với Categories ở bên trái (ẩn Categories khi showSmallTitle)
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF334DCC),
                        Color(0xFF4F4CBF),
                        Color(0xFF9722C9),
                      ],
                    ).createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 28,
                        ),
                        if (!_showSmallTitle()) ...[
                          Text(
                            'Categories',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Small title ở chính giữa màn hình với fade animation
              AnimatedOpacity(
                opacity: _showSmallTitle() ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _showSmallTitle()
                    ? Text(
                        widget.categoryName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          // Big title ẩn khi scroll >= 150
          if (_showBigTitle()) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                widget.categoryName,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
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
