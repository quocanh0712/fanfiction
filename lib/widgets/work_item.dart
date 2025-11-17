import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/work_model.dart';
import '../services/saved_works_service.dart';
import '../services/work_service.dart';
import '../presentation/work_detail_bottom_sheet.dart';
import 'loading_indicator.dart';

class WorkItem extends StatefulWidget {
  final WorkModel work;
  final Map<String, bool>? expandedTags;
  final Function(String)? onTagExpanded;
  final VoidCallback? onWorkTap;
  final Function(String)? onUnsaved; // Callback when work is unsaved

  const WorkItem({
    super.key,
    required this.work,
    this.expandedTags,
    this.onTagExpanded,
    this.onWorkTap,
    this.onUnsaved,
  });

  @override
  State<WorkItem> createState() => _WorkItemState();
}

class _WorkItemState extends State<WorkItem> {
  final SavedWorksService _savedWorksService = SavedWorksService();
  final WorkService _workService = WorkService();
  bool _isSaved = false;
  bool _isLoadingSaved = true;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    final saved = await _savedWorksService.isWorkSaved(widget.work.id);
    if (mounted) {
      setState(() {
        _isSaved = saved;
        _isLoadingSaved = false;
      });
    }
  }

  Future<void> _toggleSave() async {
    print(
      '💾 _toggleSave called for work: ${widget.work.title} (id: ${widget.work.id})',
    );
    final wasSaved = _isSaved;
    print('📊 Current saved state: $wasSaved');

    final success = await _savedWorksService.toggleSaveWork(widget.work);
    print('✅ Toggle result: $success');

    if (success && mounted) {
      setState(() {
        _isSaved = !_isSaved;
      });
      print('📊 New saved state: $_isSaved');

      // If work was saved and now unsaved, notify parent
      if (wasSaved && !_isSaved && widget.onUnsaved != null) {
        print('🔔 Notifying parent that work was unsaved: ${widget.work.id}');
        widget.onUnsaved!(widget.work.id);
        print('✅ Callback executed');
      } else {
        print(
          'ℹ️ Not calling onUnsaved (wasSaved: $wasSaved, isSaved: $_isSaved, hasCallback: ${widget.onUnsaved != null})',
        );
      }
    } else {
      print('❌ Toggle failed or widget not mounted');
    }
  }

  Future<void> _handleWorkTap() async {
    if (!context.mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: const Center(child: LoadingIndicator(color: Color(0xFF7d26cd))),
      ),
    );

    try {
      final workContent = await _workService.getWorkContent(widget.work.id);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Wait a bit to ensure dialog is fully closed
      await Future.delayed(const Duration(milliseconds: 200));

      // Show bottom sheet using root navigator
      if (context.mounted) {
        final rootContext = Navigator.of(context, rootNavigator: true).context;
        if (rootContext.mounted) {
          showModalBottomSheet(
            context: rootContext,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) =>
                WorkDetailBottomSheet(workContent: workContent),
          ).then((_) {
            // After bottom sheet is closed, call callback if provided
            if (widget.onWorkTap != null) {
              widget.onWorkTap!();
            }
          });
        }
      }
    } catch (e) {
      // Close loading dialog on error
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading work: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Widget _buildTagsSection() {
    final isExpanded = widget.expandedTags?[widget.work.id] ?? false;
    final tagsCount = widget.work.tags.length;

    if (tagsCount <= 1) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: widget.work.tags.map((tag) => _buildPillTag(tag)).toList(),
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: isExpanded
            ? [
                ...widget.work.tags.map((tag) => _buildPillTag(tag)),
                GestureDetector(
                  onTap: () {
                    if (widget.onTagExpanded != null) {
                      widget.onTagExpanded!(widget.work.id);
                    }
                  },
                  child: _buildPillTag('Show less'),
                ),
              ]
            : [
                _buildPillTag(widget.work.tags[0]),
                GestureDetector(
                  onTap: () {
                    if (widget.onTagExpanded != null) {
                      widget.onTagExpanded!(widget.work.id);
                    }
                  },
                  child: _buildPillTag('and ${tagsCount - 1} more...'),
                ),
              ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _handleWorkTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with save icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.work.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleSave,
                  child: _isLoadingSaved
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: LoadingIndicator(
                            size: 24,
                            color: Colors.white,
                          ),
                        )
                      : SvgPicture.asset(
                          _isSaved
                              ? 'assets/icons/ic_save_fill.svg'
                              : 'assets/icons/ic_save.svg',
                          width: 24,
                          height: 24,
                          colorFilter: _isSaved
                              ? ColorFilter.mode(
                                  const Color(0xFF7d26cd), // Purple when saved
                                  BlendMode.srcIn,
                                )
                              : ColorFilter.mode(
                                  Colors.white.withOpacity(
                                    0.7,
                                  ), // Semi-transparent white when not saved
                                  BlendMode.srcIn,
                                ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Tags
            if (widget.work.tags.isNotEmpty) _buildTagsSection(),
            if (widget.work.tags.isNotEmpty) const SizedBox(height: 12),
            // Summary
            Text(
              widget.work.summary,
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
                if (widget.work.stats.language != null)
                  _buildPillTag(widget.work.stats.language!),
                if (widget.work.stats.chapters != null)
                  _buildPillTag(widget.work.stats.chapters!),
                if (widget.work.stats.words != null)
                  _buildPillTag(widget.work.stats.words!),
                if (widget.work.stats.collections != null)
                  _buildPillTag(widget.work.stats.collections!),
                if (widget.work.stats.comments != null)
                  _buildPillTag(widget.work.stats.comments!),
                if (widget.work.stats.kudos != null)
                  _buildPillTag(widget.work.stats.kudos!),
                if (widget.work.stats.hits != null)
                  _buildPillTag(widget.work.stats.hits!),
                if (widget.work.stats.bookmarks != null)
                  _buildPillTag(widget.work.stats.bookmarks!),
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
                const SizedBox(width: 5),
                Text(
                  widget.work.author,
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
}
