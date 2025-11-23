import '../models/work_model.dart';
import '../services/work_service.dart';

class NewWorksRepository {
  static final NewWorksRepository _instance = NewWorksRepository._internal();
  factory NewWorksRepository() => _instance;
  NewWorksRepository._internal();

  final WorkService _workService = WorkService();

  List<WorkModel> _works = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  List<WorkModel> get works => _works;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  /// Load new works from API
  Future<void> loadNewWorks() async {
    if (_isLoading || _isInitialized) return;

    _isLoading = true;
    _error = null;

    try {
      _works = await _workService.getNewWorks();
      _isLoading = false;
      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isInitialized = true;
    }
  }

  /// Refresh new works
  Future<void> refreshNewWorks() async {
    _isInitialized = false;
    _error = null;
    await loadNewWorks();
  }
}
