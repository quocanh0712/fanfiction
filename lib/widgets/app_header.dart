import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class AppHeader extends StatefulWidget {
  final String? leftIconPath;
  final String title;
  final Widget? rightAction;
  final bool? isHaveIcon;
  final VoidCallback? onLeftIconTap;
  final VoidCallback? onTitleTap;
  final VoidCallback? onRightActionTap;
  final Function(String)? onSearchChanged;
  final String? searchHint;

  const AppHeader({
    super.key,
    this.leftIconPath = "assets/icons/ic_header_robot.svg",
    this.title = 'Storedo',
    this.rightAction,
    this.onLeftIconTap,
    this.onTitleTap,
    this.onRightActionTap,
    this.isHaveIcon,
    this.onSearchChanged,
    this.searchHint,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (_isSearchMode) {
        // Focus on search field when entering search mode
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      } else {
        // Clear search when exiting search mode
        _searchController.clear();
        widget.onSearchChanged?.call('');
      }
    });
  }

  void _onSearchChanged(String value) {
    widget.onSearchChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 55),
        const Divider(color: Colors.white24, height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: SizedBox(
            height: 30, // Fixed height to prevent Row from expanding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _isSearchMode ? const SizedBox(width: 20) : _buildLeftIcon(),
                _isSearchMode ? _buildSearchField() : _buildTitle(),
                _buildRightAction(),
              ],
            ),
          ),
        ),
        const Divider(color: Colors.white24, height: 12),
      ],
    );
  }

  Widget _buildLeftIcon() {
    if (widget.leftIconPath == null) {
      return const SizedBox(width: 20, height: 20);
    }

    final iconWidget = SizedBox(
      width: 20,
      height: 20,
      child: SvgPicture.asset(widget.leftIconPath!, width: 20, height: 20),
    );

    return widget.onLeftIconTap != null
        ? GestureDetector(onTap: widget.onLeftIconTap, child: iconWidget)
        : iconWidget;
  }

  Widget _buildTitle() {
    final titleWidget = Padding(
      padding: const EdgeInsets.only(bottom:3),
      child: Text(
        widget.title,
        style: GoogleFonts.playfairDisplay(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );

    return widget.onTitleTap != null
        ? GestureDetector(onTap: widget.onTitleTap, child: titleWidget)
        : titleWidget;
  }

  Widget _buildSearchField() {
    return Expanded(
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
        cursorColor: Colors.white,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: widget.searchHint ?? 'Search works, tags...',
          hintStyle: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.5),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildRightAction() {
    if (widget.rightAction != null) {
      return widget.onRightActionTap != null
          ? GestureDetector(
              onTap: widget.onRightActionTap,
              child: widget.rightAction!,
            )
          : widget.rightAction!;
    }

    if (widget.isHaveIcon == false) {
      return const SizedBox(width: 20);
    }

    // Show close icon when in search mode, search icon otherwise
    if (_isSearchMode) {
      return GestureDetector(
        onTap: _toggleSearchMode,
        child: const Icon(Icons.close, size: 20, color: Colors.white),
      );
    }

    return GestureDetector(
      onTap: _toggleSearchMode,
      child: const Icon(Icons.search, size: 20, color: Colors.white),
    );
  }
}
