import 'package:dio/dio.dart';
import '../models/category_model.dart';
import 'api_client.dart';

class CategoryService {
  final ApiClient _apiClient = ApiClient();

  CategoryService() {
    _apiClient.init();
  }

  /// Get all categories
  ///
  /// Returns a list of all media categories
  /// Example: GET https://fandom-gg.onrender.com/categories
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final response = await _apiClient.dio.get('/categories');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get category by ID
  ///
  /// Returns a specific category by its ID
  Future<CategoryModel?> getCategoryById(String categoryId) async {
    try {
      final response = await _apiClient.dio.get('/categories/$categoryId');

      if (response.statusCode == 200) {
        return CategoryModel.fromJson(response.data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Search categories by name
  Future<List<CategoryModel>> searchCategories(String query) async {
    try {
      final response = await _apiClient.dio.get(
        '/categories',
        queryParameters: {'search': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        return 'Server error: ${error.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'Connection error. Please check your internet connection.';
      default:
        return 'An unexpected error occurred: ${error.message}';
    }
  }
}
