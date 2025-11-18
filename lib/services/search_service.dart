import 'package:dio/dio.dart';
import '../models/search_response_model.dart';
import 'api_client.dart';

class SearchService {
  final ApiClient _apiClient = ApiClient();

  SearchService() {
    _apiClient.init();
  }

  /// Search works by query with pagination
  ///
  /// Parameters:
  /// - [query]: The search query (required)
  /// - [page]: Page number (default: 1)
  ///
  /// Example: GET https://fandom-gg.onrender.com/search?query=one&page=1
  ///
  /// Returns [SearchResponse] containing:
  /// - totalResults: Total number of results
  /// - page: Current page number
  /// - works: List of works for the current page
  Future<SearchResponse> searchWorks(String query, {int page = 1}) async {
    try {
      final response = await _apiClient.dio.get(
        '/search',
        queryParameters: {'query': query, 'page': page},
      );

      if (response.statusCode == 200) {
        return SearchResponse.fromJson(response.data as Map<String, dynamic>);
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
