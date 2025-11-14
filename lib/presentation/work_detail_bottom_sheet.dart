import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/work_content_model.dart';

class WorkDetailBottomSheet extends StatefulWidget {
  final WorkContentModel workContent;

  const WorkDetailBottomSheet({super.key, required this.workContent});

  @override
  State<WorkDetailBottomSheet> createState() => _WorkDetailBottomSheetState();
}

class _WorkDetailBottomSheetState extends State<WorkDetailBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  WorkContentMetadata get _metadata => widget.workContent.metadata;
  bool _showAllCharacters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height * 0.9;

    return Container(
      height: screenHeight,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Top row with more options
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.end,
                //   children: [
                //     IconButton(
                //       icon: const Icon(Icons.more_vert, color: Colors.white),
                //       onPressed: () {
                //         // TODO: Show more options menu
                //       },
                //     ),
                //   ],
                // ),
                // Title
                Text(
                  widget.workContent.title,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Author
                GestureDetector(
                  onTap: () {
                    // TODO: Navigate to author profile
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'by ${widget.workContent.author}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.white60,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Read button
                GestureDetector(
                  onTap: () {
                    if (widget.workContent.chapters.isNotEmpty) {
                      final firstChapter = widget.workContent.chapters[0];
                      context.push(
                        '/read-story',
                        extra: {
                          'chapter': firstChapter,
                          'workTitle': widget.workContent.title,
                          'author': widget.workContent.author,
                          'currentChapterIndex': 0,
                          'totalChapters': widget.workContent.chapters.length,
                        },
                      );
                    }
                  },
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.white, width: 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Read',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Tab bar
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SizedBox(
                    height: 40,
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: 'About'),
                        Tab(text: 'Chapters'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Horizontal scrollable metadata bar
                _buildMetadataScrollBar(),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildAboutTab(), _buildChaptersTab()],
            ),
          ),
        ],
      ),
    );
  }

  String? _getMetadataValue(String key, {List<String> fallbacks = const []}) {
    final keys = [key, ...fallbacks];
    for (final candidate in keys) {
      final value = _metadata.getString(candidate);
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  List<String> _getMetadataList(
    String key, {
    List<String> fallbacks = const [],
  }) {
    final keys = [key, ...fallbacks];
    for (final candidate in keys) {
      final value = _metadata.getList(candidate);
      if (value.isNotEmpty) return value;
    }
    return [];
  }

  bool _metadataContainsKey(String key, {List<String> fallbacks = const []}) {
    final keys = [key, ...fallbacks];
    for (final candidate in keys) {
      if (_metadata.containsKey(candidate)) return true;
    }
    return false;
  }

  Widget _buildMetadataScrollBar() {
    final List<MapEntry<String, String>> items = [];

    // Helper to add item if exists
    void addIfExists(String key, {List<String> fallbacks = const []}) {
      final value = _getMetadataValue(key, fallbacks: fallbacks);
      if (value != null && value.isNotEmpty) {
        items.add(MapEntry(key, value));
      }
    }

    // Add metadata items in order
    addIfExists('Language');
    addIfExists('Words');
    addIfExists('Chapters');
    addIfExists('Available Offline');
    addIfExists('Comments');
    addIfExists('Kudos');
    addIfExists('Bookmarks');
    addIfExists('Hits');

    if (items.isEmpty) return const SizedBox.shrink();

    // Helper to get icon for metadata key
    IconData? _getIconForKey(String key) {
      switch (key.toLowerCase()) {
        case 'language':
          return Icons.language;
        case 'words':
          return Icons.text_fields;
        case 'chapters':
          return Icons.menu_book;
        case 'available offline':
          return Icons.download;
        case 'comments':
          return Icons.comment;
        case 'kudos':
          return Icons.favorite;
        case 'bookmarks':
          return Icons.bookmark;
        case 'hits':
          return Icons.visibility;
        default:
          return null;
      }
    }

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final entry = items[index];
          final icon = _getIconForKey(entry.key);

          return Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey.shade900, Colors.grey.shade800],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  entry.key,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  entry.value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          _buildSection(
            'Summary',
            Text(
              widget.workContent.summary,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white38),
          const SizedBox(height: 12),
          // Rating
          _buildSection(
            'Rating',
            Text(
              _getMetadataValue('Rating') ?? 'Not Rated',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white38),
          const SizedBox(height: 12),
          // Archive Warning
          if (_getMetadataValue('Archive Warning') != null)
            _buildSection(
              'Archive Warning',
              _buildChip(_getMetadataValue('Archive Warning')!),
            ),
          if (_getMetadataValue('Archive Warning') != null)
            const SizedBox(height: 12),
          Divider(color: Colors.white38),
          const SizedBox(height: 12),
          // Category
          if (_getMetadataValue('Category') != null)
            _buildSection(
              'Category',
              Text(
                _getMetadataValue('Category')!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
          if (_getMetadataValue('Category') != null) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white38),
            const SizedBox(height: 12),
          ],
          // Fandoms
          if (_getMetadataValue('Fandom') != null)
            _buildSection(
              'Fandoms',
              Text(
                _getMetadataValue('Fandom')!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
          if (_getMetadataValue('Fandom') != null) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white38),
            const SizedBox(height: 12),
          ],
          // Relationships
          if (_getMetadataValue('Relationships', fallbacks: ['Relationship']) !=
              null)
            _buildSection(
              'Relationships',
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getMetadataList(
                  'Relationships',
                  fallbacks: ['Relationship'],
                ).map((rel) => _buildChip(rel)).toList(),
              ),
            ),
          if (_getMetadataValue('Relationships', fallbacks: ['Relationship']) !=
              null) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white38),
            const SizedBox(height: 12),
          ],

          // Characters
          if (_getMetadataValue('Characters') != null)
            _buildSection(
              'Characters',
              _buildCharacterTags(_getMetadataList('Characters')),
            ),
          if (_getMetadataValue('Characters') != null) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white38),
            const SizedBox(height: 12),
          ],
          // Additional Tags
          if (_getMetadataValue('Additional Tags') != null)
            _buildSection(
              'Additional Tags',
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getMetadataList(
                  'Additional Tags',
                ).map((tag) => _buildChip(tag)).toList(),
              ),
            ),
          if (_getMetadataValue('Additional Tags') != null) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white38),
            const SizedBox(height: 12),
          ],
          // Published
          if (_getMetadataValue('Published') != null)
            _buildSection(
              'Published',
              Text(
                _formatDate(_getMetadataValue('Published')!),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
          if (_getMetadataValue('Published') != null) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white38),
            const SizedBox(height: 12),
          ],
          // Updated
          if (_getMetadataValue('Updated') != null)
            _buildSection(
              'Updated',
              Text(
                _formatDate(_getMetadataValue('Updated')!),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
          if (_getMetadataValue('Updated') != null) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white38),
            const SizedBox(height: 12),
          ],
          // Story Id (if exists)
          if (_metadataContainsKey('Story Id', fallbacks: ['story_id']))
            _buildSection(
              'Story Id',
              Text(
                _getMetadataValue('Story Id') ??
                    _getMetadataValue('story_id') ??
                    '',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${days[date.weekday - 1]} ${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildCharacterTags(List<String> characters) {
    if (characters.isEmpty) return const SizedBox.shrink();

    const maxVisible = 3;
    final isExpanded = _showAllCharacters;
    final visibleChars = isExpanded
        ? characters
        : characters.take(maxVisible).toList();
    final remaining = characters.length - visibleChars.length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...visibleChars.map((char) => _buildChip(char)),
        if (!isExpanded && remaining > 0)
          GestureDetector(
            onTap: () {
              setState(() {
                _showAllCharacters = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.expand_more, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'and $remaining more...',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (isExpanded && characters.length > maxVisible)
          GestureDetector(
            onTap: () {
              setState(() {
                _showAllCharacters = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.expand_less, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'show less',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChaptersTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: widget.workContent.chapters.length,
      separatorBuilder: (context, index) =>
          const Divider(color: Colors.white38, height: 1),
      itemBuilder: (context, index) {
        final chapter = widget.workContent.chapters[index];
        final chapterNumber = index + 1;

        // Extract chapter title (remove "Chapter X:" prefix if exists)
        String displayTitle = chapter.title;
        if (displayTitle.contains(':')) {
          final parts = displayTitle.split(':');
          if (parts.length > 1) {
            displayTitle = parts.sublist(1).join(':').trim();
          }
        }

        return InkWell(
          onTap: () {
            context.push(
              '/read-story',
              extra: {
                'chapter': chapter,
                'workTitle': widget.workContent.title,
                'author': widget.workContent.author,
                'currentChapterIndex': index,
                'totalChapters': widget.workContent.chapters.length,
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chapter $chapterNumber',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$chapterNumber. $displayTitle',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.white, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}
