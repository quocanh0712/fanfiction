import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/work_content_model.dart';

class ReadStoryScreen extends StatelessWidget {
  final ChapterModel chapter;
  final String workTitle;
  final String author;

  const ReadStoryScreen({
    super.key,
    required this.chapter,
    required this.workTitle,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header with close button
          SizedBox(height: 50,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40), // Spacer for centering
                Expanded(
                  child: Column(
                    children: [
                      // Chapter number
                      Text(
                        chapter.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),

                    ],
                  ),
                ),
                // Close button
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => context.pop(),
                  iconSize: 24,
                ),
              ],
            ),
          ),
          // Content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              child: _buildFormattedContent(chapter.content),
            ),
          ),
          // Bottom navigation button

        ],
      ),
    );
  }

  String _extractChapterNumber(String title) {
    // Extract "Chapter 1" from "Chapter 1: Prologue: A New Journey"
    if (title.toLowerCase().startsWith('chapter')) {
      final parts = title.split(':');
      if (parts.isNotEmpty) {
        return parts[0].trim();
      }
    }
    return 'Chapter';
  }

  String _extractChapterTitle(String title) {
    // Extract title after "Chapter X:" or "Chapter X: Prologue:"
    if (title.contains(':')) {
      final parts = title.split(':');
      if (parts.length >= 2) {
        // Skip first part (Chapter X) and join the rest
        return parts.sublist(1).join(':').trim();
      }
    }
    return title;
  }

  Widget _buildFormattedContent(String content) {
    // Split content by newlines
    final lines = content.split('\n');
    final List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) {
        // Add spacing for empty lines
        widgets.add(const SizedBox(height: 16));
        continue;
      }

      // Check if line is a heading (starts and ends with ** or is all caps)
      final isFullBoldHeading =
          line.startsWith('**') && line.endsWith('**') && line.length > 4;
      final isCapsHeading =
          line.length > 0 &&
          line == line.toUpperCase() &&
          line.length < 50 &&
          !line.contains('**');

      // Check for bold text (**text**)
      if (line.contains('**')) {
        if (isFullBoldHeading) {
          // Full line is bold heading
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 8),
              child: Text(
                line.replaceAll('**', ''),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          );
        } else {
          // Mixed bold and normal text
          widgets.add(_buildBoldText(line));
        }
      } else if (isCapsHeading) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Text(
              line,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              line,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                height: 1.6,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildBoldText(String text) {
    // Parse text with **bold** markers
    final List<TextSpan> spans = [];
    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');

    int lastIndex = 0;
    for (final match in boldRegex.allMatches(text)) {
      // Add text before bold
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        );
      }

      // Add bold text
      spans.add(
        TextSpan(
          text: match.group(1),
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        text: TextSpan(
          children: spans,
          style: GoogleFonts.poppins(
            fontSize: 15,
            height: 1.6,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
