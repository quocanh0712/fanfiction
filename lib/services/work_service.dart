import 'package:dio/dio.dart';
import '../models/work_model.dart';
import '../models/work_content_model.dart';
import 'api_client.dart';

class WorkService {
  final ApiClient _apiClient = ApiClient();

  WorkService() {
    _apiClient.init();
  }

  /// Get works by fandom ID with pagination
  ///
  /// Parameters:
  /// - [fandomId]: The fandom ID (required)
  /// - [page]: Page number (default: 1)
  ///
  /// Example: GET https://fandom-gg.onrender.com/works?fandom_id=fnd_7a72626adc71&page=1
  Future<List<WorkModel>> getWorksByFandom(
    String fandomId, {
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/works',
        queryParameters: {'fandom_id': fandomId, 'page': page},
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

  /// Get all works
  ///
  /// Example: GET https://fandom-gg.onrender.com/works
  Future<List<WorkModel>> getAllWorks({int page = 1}) async {
    try {
      final response = await _apiClient.dio.get(
        '/works',
        queryParameters: {'page': page},
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

  /// Search works
  Future<List<WorkModel>> searchWorks(String query, {int page = 1}) async {
    try {
      final response = await _apiClient.dio.get(
        '/works',
        queryParameters: {'search': query, 'page': page},
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

  /// Get new works
  ///
  /// Example: GET https://fandom-gg.onrender.com/new
  Future<List<WorkModel>> getNewWorks() async {
    try {
      final response = await _apiClient.dio.get('/new');

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

  /// Get work content by work ID
  ///
  /// Parameters:
  /// - [workId]: The work ID (required)
  ///
  /// Example: GET https://fandom-gg.onrender.com/work/content?work_id=wrk_9ad21178eac1
  Future<WorkContentModel> getWorkContent(String workId) async {
    try {
      final response = await _apiClient.dio.get(
        '/work/content',
        queryParameters: {'work_id': workId},
      );

      if (response.statusCode == 200) {
        return WorkContentModel.fromJson(response.data as Map<String, dynamic>);
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
