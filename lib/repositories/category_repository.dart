import '../models/category_model.dart';
import '../services/category_service.dart';

class CategoryRepository {
  static final CategoryRepository _instance = CategoryRepository._internal();
  factory CategoryRepository() => _instance;
  CategoryRepository._internal();

  final CategoryService _categoryService = CategoryService();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  /// Load categories from API
  Future<void> loadCategories() async {
    if (_isLoading || _isInitialized) return;

    _isLoading = true;
    _error = null;

    try {
      _categories = await _categoryService.getAllCategories();
      _isLoading = false;
      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isInitialized = true;
    }
  }

  /// Refresh categories
  Future<void> refreshCategories() async {
    _isInitialized = false;
    _error = null;
    await loadCategories();
  }

  /// Get category by ID
  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Search categories
  List<CategoryModel> searchCategories(String query) {
    if (query.isEmpty) return _categories;

    return _categories.where((category) {
      return category.name.toLowerCase().contains(query.toLowerCase()) ||
          category.encodedName.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}
