import 'package:dio/dio.dart';
import '../models/work_model.dart';
import 'api_client.dart';

class WorkService {
  final ApiClient _apiClient = ApiClient();

  WorkService() {
    _apiClient.init();
  }

  /// Get all works
  ///
  /// Returns a list of all works
  /// Example: GET https://fandom-gg.onrender.com/works
  Future<List<WorkModel>> getAllWorks({int? page, int? limit}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.dio.get(
        '/works',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => WorkModel.fromJson(json)).toList();
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

  /// Get work by ID
  Future<WorkModel?> getWorkById(String workId) async {
    try {
      final response = await _apiClient.dio.get('/works/$workId');

      if (response.statusCode == 200) {
        return WorkModel.fromJson(response.data);
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

  /// Get works by fandom
  Future<List<WorkModel>> getWorksByFandom(String fandomId) async {
    try {
      final response = await _apiClient.dio.get(
        '/works',
        queryParameters: {'fandom': fandomId},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => WorkModel.fromJson(json)).toList();
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

  /// Get work content by ID
  Future<String?> getWorkContent(String workId) async {
    try {
      final response = await _apiClient.dio.get('/works/$workId/content');

      if (response.statusCode == 200) {
        return response.data['content'] as String?;
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

  /// Search works
  Future<List<WorkModel>> searchWorks(String query) async {
    try {
      final response = await _apiClient.dio.get(
        '/works',
        queryParameters: {'search': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => WorkModel.fromJson(json)).toList();
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
