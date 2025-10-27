import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/fandom_service.dart';
import '../models/fandom_model.dart';

class FandomScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final VoidCallback onBack;

  const FandomScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.onBack,
  });

  @override
  State<FandomScreen> createState() => _FandomScreenState();
}

class _FandomScreenState extends State<FandomScreen> {
  final FandomService _fandomService = FandomService();
  List<FandomModel> _fandoms = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFandoms();
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
      final kCount = (count / 1000).toStringAsFixed(0);
      return '$kCount stories';
    }
    return '$count stories';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            SizedBox(height: 50),
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
            onTap: () => widget.onBack(),
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
                    'Categories',
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
              widget.categoryName,
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
            const Icon(CupertinoIcons.search, color: Colors.white70, size: 20),
            // const Icon(Icons.search, color: Colors.white54, size: 20),
            const SizedBox(width: 12),
            Text(
              'Search',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
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

    if (_fandoms.isEmpty) {
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
      padding: EdgeInsets.zero,
      itemCount: _fandoms.length,
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(left: 16),
        child: const Divider(color: Color(0xFF2A2A2A), thickness: 1, height: 1),
      ),
      itemBuilder: (context, index) {
        return _buildFandomItem(_fandoms[index]);
      },
    );
  }

  Widget _buildFandomItem(FandomModel fandom) {
    return InkWell(
      onTap: () {
        // Navigate to fandom details or works list
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
