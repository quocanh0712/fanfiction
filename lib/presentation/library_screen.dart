import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
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

class _LibraryScreenState extends State<LibraryScreen>
    with WidgetsBindingObserver {
  final SavedWorksService _savedWorksService = SavedWorksService();
  List<WorkModel> _savedWorks = [];
  List<WorkModel> _filteredWorks = [];
  bool _isLoading = true;
  final Map<String, bool> _expandedTags = {};
  String _searchQuery = '';
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedWorks(isInitialLoad: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload when app comes back to foreground
    if (state == AppLifecycleState.resumed && _hasLoadedOnce) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _loadSavedWorks(isInitialLoad: false);
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload works when screen becomes visible again
    // This helps refresh the list when navigating back from other screens
    // Only reload if we've already loaded once (to avoid reloading on first build)
    if (_hasLoadedOnce) {
      // Use a small delay to ensure SharedPreferences has been updated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _loadSavedWorks(isInitialLoad: false);
          }
        });
      });
    }
  }

  Future<void> _loadSavedWorks({bool isInitialLoad = false}) async {
    print('📚 _loadSavedWorks called (isInitialLoad: $isInitialLoad)');
    if (isInitialLoad) {
      setState(() {
        _isLoading = true;
      });
    }
    // Note: RefreshIndicator automatically shows loading indicator during refresh

    try {
      final savedWorks = await _savedWorksService.getSavedWorks();
      print('📚 Loaded ${savedWorks.length} saved works');
      if (mounted) {
        setState(() {
          _savedWorks = savedWorks;
          _filteredWorks = savedWorks;
          _isLoading = false;
          _hasLoadedOnce = true; // Mark that we've loaded at least once
          // Force rebuild AnimatedList on reload by creating new key
          if (!isInitialLoad) {
            _listKey = GlobalKey<AnimatedListState>();
          }
        });
        _filterWorks(_searchQuery);
      }
    } catch (e) {
      print('❌ Error loading saved works: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterWorks(String query) {
    print('🔍 _filterWorks called with query: "$query"');
    print('📊 BEFORE FILTER - _savedWorks.length: ${_savedWorks.length}');
    print('📊 BEFORE FILTER - _filteredWorks.length: ${_filteredWorks.length}');

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

    print('📊 AFTER FILTER - _filteredWorks.length: ${_filteredWorks.length}');
    print(
      '📋 AFTER FILTER - _filteredWorks IDs: ${_filteredWorks.map((w) => w.id).toList()}',
    );
  }

  void _removeWork(String workId) {
    print('🔄 _removeWork called with workId: $workId');
    print('📊 BEFORE REMOVE - _savedWorks.length: ${_savedWorks.length}');
    print('📊 BEFORE REMOVE - _filteredWorks.length: ${_filteredWorks.length}');
    print(
      '📋 BEFORE REMOVE - _savedWorks IDs: ${_savedWorks.map((w) => w.id).toList()}',
    );
    print(
      '📋 BEFORE REMOVE - _filteredWorks IDs: ${_filteredWorks.map((w) => w.id).toList()}',
    );

    // Find the index in filtered list
    final index = _filteredWorks.indexWhere((work) => work.id == workId);
    print('📍 Found index: $index (total items: ${_filteredWorks.length})');

    if (index == -1) {
      print('❌ Work not found in filtered list');
      return;
    }

    // Safety check: ensure index is valid
    if (index < 0 || index >= _filteredWorks.length) {
      print('❌ Invalid index: $index (list length: ${_filteredWorks.length})');
      return;
    }

    // Get the work to remove BEFORE removing from list
    final removedWork = _filteredWorks[index];
    final isOnlyItem = _filteredWorks.length == 1;
    print('📦 Removing work: ${removedWork.title}');
    print('📊 Is only item: $isOnlyItem');

    // Count how many items will be removed from _savedWorks
    final beforeSavedCount = _savedWorks.length;
    final matchingSavedCount = _savedWorks
        .where((work) => work.id == workId)
        .length;
    print('🔍 Found $matchingSavedCount item(s) with workId in _savedWorks');

    // Remove from _filteredWorks FIRST (using the known index)
    _filteredWorks.removeAt(index);
    print(
      '✅ Removed from _filteredWorks at index $index. New length: ${_filteredWorks.length}',
    );

    // Remove from _savedWorks - find the FIRST matching index and remove only ONE item
    final savedIndex = _savedWorks.indexWhere((work) => work.id == workId);
    if (savedIndex != -1) {
      _savedWorks.removeAt(savedIndex);
      print(
        '✅ Removed from _savedWorks at index $savedIndex. New length: ${_savedWorks.length}',
      );
    } else {
      print('⚠️ Work not found in _savedWorks (should not happen)');
    }

    print(
      '📊 AFTER REMOVE - _savedWorks.length: ${_savedWorks.length} (removed ${beforeSavedCount - _savedWorks.length} items)',
    );
    print('📊 AFTER REMOVE - _filteredWorks.length: ${_filteredWorks.length}');
    print(
      '📋 AFTER REMOVE - _savedWorks IDs: ${_savedWorks.map((w) => w.id).toList()}',
    );
    print(
      '📋 AFTER REMOVE - _filteredWorks IDs: ${_filteredWorks.map((w) => w.id).toList()}',
    );

    // Animate removal using AnimatedList
    // Skip animation for last/only item to avoid index issues
    if (!isOnlyItem && _listKey.currentState != null) {
      print('🎬 Attempting to animate removal at index: $index');
      try {
        _listKey.currentState!.removeItem(
          index,
          (context, animation) =>
              _buildAnimatedRemovalItem(removedWork, animation),
          duration: const Duration(milliseconds: 300),
        );
        print('✅ Animation started successfully');
      } catch (e) {
        // If animation fails, force rebuild AnimatedList
        print('❌ Error during animation: $e');
        print('🔄 Rebuilding AnimatedList...');
        _listKey = GlobalKey<AnimatedListState>();
      }
    } else {
      // For last/only item, rebuild AnimatedList completely
      print(
        '🔄 Rebuilding AnimatedList (isOnlyItem: $isOnlyItem, hasState: ${_listKey.currentState != null})',
      );
      _listKey = GlobalKey<AnimatedListState>();
    }

    // Update state
    print('🔄 Calling setState...');
    setState(() {});
    print('✅ _removeWork completed');
  }

  Widget _buildAnimatedRemovalItem(
    WorkModel work,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: WorkItem(
          work: work,
          expandedTags: _expandedTags,
          onTagExpanded: (workId) {
            setState(() {
              _expandedTags[workId] = !(_expandedTags[workId] ?? false);
            });
          },
          onWorkTap: () async {
            await Future.delayed(const Duration(milliseconds: 300));
            _loadSavedWorks(isInitialLoad: false);
          },
          onUnsaved: _removeWork,
        ),
      ),
    );
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
            onLeftIconTap: () async {
              // Push to chatbot suggestion screen
              await context.push('/chatbot-suggestion');
              // Reload works when returning from chatbot screen
              if (mounted && _hasLoadedOnce) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    _loadSavedWorks(isInitialLoad: false);
                  }
                });
              }
            },
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
      child: AnimatedList(
        key: _listKey,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        initialItemCount: _filteredWorks.length,
        itemBuilder: (context, index, animation) {
          // Safety check: ensure index is valid
          if (index < 0 || index >= _filteredWorks.length) {
            return const SizedBox.shrink();
          }

          final work = _filteredWorks[index];
          return Column(
            children: [
              WorkItem(
                key: ValueKey(
                  work.id,
                ), // Use ValueKey for proper item identification
                work: work,
                expandedTags: _expandedTags,
                onTagExpanded: (workId) {
                  setState(() {
                    _expandedTags[workId] = !(_expandedTags[workId] ?? false);
                  });
                },
                onWorkTap: () async {
                  await Future.delayed(const Duration(milliseconds: 300));
                  _loadSavedWorks(isInitialLoad: false);
                },
                onUnsaved: _removeWork,
              ),
              if (index < _filteredWorks.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: const Divider(
                    color: Color(0xFF2A2A2A),
                    thickness: 1,
                    height: 1,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
