import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/splash_screen.dart';
import '../presentation/home_screen.dart';
import '../presentation/fandom_screen.dart';
import '../presentation/work_screen.dart';
import '../presentation/library_screen.dart';
import '../presentation/category_screen.dart';
import '../presentation/new_screen.dart';
import '../presentation/search_screen.dart';
import '../presentation/settings_screen.dart';
import '../presentation/app_initializer.dart';
import '../presentation/read_story_screen.dart';
import '../presentation/chatbot_suggestion_screen.dart';
import '../models/work_content_model.dart';

class AppRouter {
  static const String splash = '/';
  static const String home = '/home';
  static const String library = '/home/library';
  static const String category = '/home/category';
  static const String fandom = '/home/category/fandom';
  static const String newScreen = '/home/new';
  static const String search = '/home/search';
  static const String settings = '/home/settings';

  static late final GoRouter router = GoRouter(
    initialLocation: '/app-init',
    routes: [
      GoRoute(
        path: '/app-init',
        builder: (context, state) => const AppInitializer(),
      ),
      GoRoute(path: splash, builder: (context, state) => const SplashScreen()),
      ShellRoute(
        builder: (context, state, child) {
          // Get selected tab from state
          final location = state.uri.path;
          int selectedIndex = 0;

          if (location.startsWith('/home/library') || location == '/home') {
            selectedIndex = 0;
          } else if (location.startsWith('/home/category')) {
            selectedIndex = 1;
          } else if (location.startsWith('/home/new')) {
            selectedIndex = 2;
          } else if (location.startsWith('/home/search')) {
            selectedIndex = 3;
          } else if (location.startsWith('/home/settings')) {
            selectedIndex = 4;
          }

          return HomeScreen(selectedIndex: selectedIndex, child: child);
        },
        routes: [
          // Library tab
          GoRoute(
            path: '/home/library',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const LibraryScreen()),
          ),

          // Category tab
          GoRoute(
            path: '/home/category',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const CategoryScreen()),
            routes: [
              // Fandom detail page
              GoRoute(
                path: 'fandom',
                builder: (context, state) {
                  final categoryId =
                      state.uri.queryParameters['categoryId'] ?? '';
                  // Go_router auto-decodes query parameters, so get directly
                  final categoryName =
                      state.uri.queryParameters['categoryName'] ?? '';

                  return FandomScreen(
                    categoryId: categoryId,
                    categoryName: categoryName,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'work',
                    builder: (context, state) {
                      final categoryName =
                          state.uri.queryParameters['categoryName'] ?? '';
                      final fandomName =
                          state.uri.queryParameters['fandomName'] ?? '';
                      final fandomId =
                          state.uri.queryParameters['fandomId'] ?? '';
                      final storyCount =
                          int.tryParse(
                            state.uri.queryParameters['storyCount'] ?? '0',
                          ) ??
                          0;

                      return WorkScreen(
                        categoryName: categoryName,
                        fandomName: fandomName,
                        fandomId: fandomId,
                        storyCount: storyCount,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // New tab
          GoRoute(
            path: '/home/new',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const NewScreen()),
          ),

          // Search tab
          GoRoute(
            path: '/home/search',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const SearchScreen()),
          ),

          // Settings tab
          GoRoute(
            path: '/home/settings',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const SettingsScreen()),
          ),
        ],
      ),
      // Read Story Screen (outside ShellRoute to hide bottom nav)
      GoRoute(
        path: '/read-story',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            // Fallback - should not happen
            return const Scaffold(
              body: Center(child: Text('Error: No chapter data')),
            );
          }

          final chapter = extra['chapter'] as ChapterModel;
          final workTitle = extra['workTitle'] as String? ?? '';
          final author = extra['author'] as String? ?? '';
          final currentChapterIndex = extra['currentChapterIndex'] as int? ?? 0;
          final totalChapters = extra['totalChapters'] as int? ?? 1;
          final allChapters =
              extra['allChapters'] as List<ChapterModel>? ?? [chapter];

          return ReadStoryScreen(
            chapter: chapter,
            workTitle: workTitle,
            author: author,
            currentChapterIndex: currentChapterIndex,
            totalChapters: totalChapters,
            allChapters: allChapters,
          );
        },
      ),
      // ChatBot Suggestion Screen (outside ShellRoute to hide bottom nav)
      GoRoute(
        path: '/chatbot-suggestion',
        builder: (context, state) => const ChatBotSuggestionScreen(),
      ),
    ],
  );
}
