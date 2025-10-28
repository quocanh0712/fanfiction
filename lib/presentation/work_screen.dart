import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/work_service.dart';
import '../models/work_model.dart';

class WorkScreen extends StatefulWidget {
  final String categoryName;
  final String fandomName;
  final String fandomId;

  const WorkScreen({
    super.key,
    required this.categoryName,
    required this.fandomName,
    required this.fandomId,
  });

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {
  final WorkService _workService = WorkService();
  final TextEditingController _searchController = TextEditingController();
  List<WorkModel> _works = [];
  List<WorkModel> _filteredWorks = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadWorks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            _buildHeader(),
            const SizedBox(height: 5),
            _buildSearchBar(),
            const SizedBox(height: 10),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button with coupled text
          GestureDetector(
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
                children: [
                  const Icon(Icons.chevron_left, color: Colors.white, size: 24),
                  const SizedBox(width: 4),
                  Text(
                    "Back",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              widget.fandomName,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
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
            const Icon(Icons.search, color: Colors.white70, size: 20),
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
                child: const Icon(Icons.clear, color: Colors.white70, size: 20),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              work.title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Author
            Text(
              work.author,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.7),
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
