import 'package:dio/dio.dart';
import '../models/fandom_model.dart';
import 'api_client.dart';

class FandomService {
  final ApiClient _apiClient = ApiClient();

  FandomService() {
    _apiClient.init();
  }

  /// Get all fandoms
  ///
  /// Returns a list of all fandoms
  /// Example: GET https://fandom-gg.onrender.com/fandoms
  Future<List<FandomModel>> getAllFandoms() async {
    try {
      final response = await _apiClient.dio.get('/fandoms');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => FandomModel.fromJson(json)).toList();
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

  /// Get fandoms by category
  Future<List<FandomModel>> getFandomsByCategory(String categoryId) async {
    try {
      final response = await _apiClient.dio.get(
        '/fandoms',
        queryParameters: {'category': categoryId},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => FandomModel.fromJson(json)).toList();
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

  /// Get fandom by ID
  Future<FandomModel?> getFandomById(String fandomId) async {
    try {
      final response = await _apiClient.dio.get('/fandoms/$fandomId');

      if (response.statusCode == 200) {
        return FandomModel.fromJson(response.data);
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

  /// Search fandoms by name
  Future<List<FandomModel>> searchFandoms(String query) async {
    try {
      final response = await _apiClient.dio.get(
        '/fandoms',
        queryParameters: {'search': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => FandomModel.fromJson(json)).toList();
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
