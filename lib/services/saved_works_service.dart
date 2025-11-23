import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/work_model.dart';

class SavedWorksService {
  static const String _savedWorksKey = 'saved_works';

  // Get all saved works
  Future<List<WorkModel>> getSavedWorks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedWorksJson = prefs.getStringList(_savedWorksKey) ?? [];

      final works = savedWorksJson
          .map(
            (jsonString) => WorkModel.fromJson(
              json.decode(jsonString) as Map<String, dynamic>,
            ),
          )
          .toList();

      // Remove duplicates by keeping only the first occurrence of each work ID
      final seenIds = <String>{};
      final uniqueWorks = <WorkModel>[];
      for (final work in works) {
        if (!seenIds.contains(work.id)) {
          seenIds.add(work.id);
          uniqueWorks.add(work);
        }
      }

      // If duplicates were found, save the deduplicated list back
      if (works.length != uniqueWorks.length) {
        print(
          '⚠️ Found ${works.length - uniqueWorks.length} duplicate(s) in saved works, removing...',
        );
        final uniqueWorksJson = uniqueWorks
            .map((work) => json.encode(work.toJson()))
            .toList();
        await prefs.setStringList(_savedWorksKey, uniqueWorksJson);
      }

      return uniqueWorks;
    } catch (e) {
      print('Error loading saved works: $e');
      return [];
    }
  }

  // Check if a work is saved
  Future<bool> isWorkSaved(String workId) async {
    try {
      final savedWorks = await getSavedWorks();
      return savedWorks.any((work) => work.id == workId);
    } catch (e) {
      print('Error checking if work is saved: $e');
      return false;
    }
  }

  // Save a work
  Future<bool> saveWork(WorkModel work) async {
    try {
      final savedWorks = await getSavedWorks();

      // Check if already saved
      if (savedWorks.any((w) => w.id == work.id)) {
        return true; // Already saved
      }

      // Add new work
      savedWorks.add(work);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedWorksJson = savedWorks
          .map((work) => json.encode(work.toJson()))
          .toList();

      return await prefs.setStringList(_savedWorksKey, savedWorksJson);
    } catch (e) {
      print('Error saving work: $e');
      return false;
    }
  }

  // Remove a saved work
  Future<bool> removeWork(String workId) async {
    try {
      final savedWorks = await getSavedWorks();

      // Find the FIRST matching index and remove only ONE item
      // This prevents removing multiple items if there are duplicate IDs
      final index = savedWorks.indexWhere((work) => work.id == workId);
      if (index != -1) {
        savedWorks.removeAt(index);
      } else {
        // Work not found, but return true to avoid errors
        return true;
      }

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedWorksJson = savedWorks
          .map((work) => json.encode(work.toJson()))
          .toList();

      return await prefs.setStringList(_savedWorksKey, savedWorksJson);
    } catch (e) {
      print('Error removing work: $e');
      return false;
    }
  }

  // Toggle save/unsave
  Future<bool> toggleSaveWork(WorkModel work) async {
    final isSaved = await isWorkSaved(work.id);
    if (isSaved) {
      return await removeWork(work.id);
    } else {
      return await saveWork(work);
    }
  }

  // Clear all saved works
  Future<bool> clearAllSavedWorks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_savedWorksKey);
    } catch (e) {
      print('Error clearing all saved works: $e');
      return false;
    }
  }

  // Get database size in bytes
  Future<int> getDatabaseSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedWorksJson = prefs.getStringList(_savedWorksKey) ?? [];

      // Calculate size of saved works data
      int totalSize = 0;
      for (final jsonString in savedWorksJson) {
        totalSize +=
            jsonString.length * 2; // UTF-16 encoding, 2 bytes per character
      }

      // Also get size of other SharedPreferences keys if needed
      // For now, we'll just return the saved works size
      return totalSize;
    } catch (e) {
      print('Error calculating database size: $e');
      return 0;
    }
  }
}
