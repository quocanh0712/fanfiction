import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_header.dart';
import '../repositories/new_works_repository.dart';
import '../widgets/work_item.dart';
import '../widgets/loading_indicator.dart';

class NewScreen extends StatefulWidget {
  const NewScreen({super.key});

  @override
  State<NewScreen> createState() => _NewScreenState();
}

class _NewScreenState extends State<NewScreen> {
  final NewWorksRepository _newWorksRepository = NewWorksRepository();
  final Map<String, bool> _expandedTags = {};

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121212),
      child: Column(
        children: [
          AppHeader(
            title: 'News',
            isHaveIcon: false,
            onLeftIconTap: () {
              context.push('/chatbot-suggestion');
            },
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Future<void> _loadNewWorks() async {
    await _newWorksRepository.refreshNewWorks();
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildBody() {
    if (_newWorksRepository.isLoading) {
      return const Center(child: LoadingIndicator(color: Color(0xFF7d26cd)));
    }

    final works = _newWorksRepository.works;
    if (_newWorksRepository.error != null && works.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadNewWorks,
        color: const Color(0xFF7d26cd),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error loading works',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _newWorksRepository.error!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (works.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadNewWorks,
        color: const Color(0xFF7d26cd),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Text(
                'No new works available',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNewWorks,
      color: const Color(0xFF7d26cd),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: works.length,
        separatorBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(left: 16),
          child: const Divider(
            color: Color(0xFF2A2A2A),
            thickness: 1,
            height: 1,
          ),
        ),
        itemBuilder: (context, index) {
          final work = works[index];
          return WorkItem(
            work: work,
            expandedTags: _expandedTags,
            onTagExpanded: (workId) {
              setState(() {
                _expandedTags[workId] = !(_expandedTags[workId] ?? false);
              });
            },
          );
        },
      ),
    );
  }
}
