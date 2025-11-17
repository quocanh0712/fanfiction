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

      return savedWorksJson
          .map(
            (jsonString) => WorkModel.fromJson(
              json.decode(jsonString) as Map<String, dynamic>,
            ),
          )
          .toList();
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
      savedWorks.removeWhere((work) => work.id == workId);

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
}
