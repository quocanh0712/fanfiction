import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;
  static const String baseUrl = 'https://fandom-gg.onrender.com';

  Dio get dio => _dio;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(CurlInterceptor());

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, error: true),
      );
    }
  }
}

class CurlInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _printCurlCommand(options);
    super.onRequest(options, handler);
  }

  void _printCurlCommand(RequestOptions options) {
    final buffer = StringBuffer();

    // Start curl command
    buffer.writeln('\n${"=" * 60}');
    buffer.writeln('🌐 CURL REQUEST');
    buffer.writeln('${"=" * 60}');

    // Method and URL
    buffer.writeln('\n🔹 Method: ${options.method.toUpperCase()}');
    buffer.writeln('🔹 URL: ${options.uri}');

    // Headers
    if (options.headers.isNotEmpty) {
      buffer.writeln('\n📋 Headers:');
      options.headers.forEach((key, value) {
        buffer.writeln('   $key: $value');
      });
    }

    // Query parameters
    if (options.queryParameters.isNotEmpty) {
      buffer.writeln('\n🔍 Query Parameters:');
      options.queryParameters.forEach((key, value) {
        buffer.writeln('   $key: $value');
      });
    }

    // Request data
    if (options.data != null) {
      buffer.writeln('\n📦 Request Body:');
      try {
        final jsonString = options.data is FormData
            ? '[FormData: ${options.data.fields}]'
            : options.data.toString();
        buffer.writeln('   $jsonString');
      } catch (e) {
        buffer.writeln('   ${options.data}');
      }
    }

    // Build curl command
    final curlCommand = _buildCurlCommand(options);
    final postmanJson = _buildPostmanCollection(options);

    buffer.writeln('\n💻 CURL Command (Copy to Postman):');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(curlCommand);
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    buffer.writeln('\n📋 Postman Collection JSON:');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(postmanJson);
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    buffer.writeln('\n${"=" * 60}\n');

    print(buffer.toString());
  }

  String _buildCurlCommand(RequestOptions options) {
    final buffer = StringBuffer();

    // Add URL (with query params if any)
    String url = '${options.baseUrl}${options.path}';
    if (options.queryParameters.isNotEmpty) {
      final queryString = options.queryParameters.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
          )
          .join('&');
      url = '$url?$queryString';
    }

    // Build simple curl command that Postman can import
    buffer.write("curl -X ${options.method}");

    // Add headers (skip Content-Type if it's application/json, Postman adds it automatically)
    options.headers.forEach((key, value) {
      // Skip Content-Type header for cleaner Postman import
      if (key.toLowerCase() != 'content-type') {
        buffer.write(" -H '${key}: ${value}'");
      }
    });

    // Add URL
    buffer.write(" '$url'");

    // Add data for POST/PUT/PATCH
    if (options.data != null &&
        options.method != 'GET' &&
        options.data is! FormData) {
      String dataString;
      if (options.data is Map || options.data is List) {
        // Convert to JSON string
        try {
          dataString = options.data
              .toString()
              .replaceAll(', ', ',')
              .replaceAll(': ', ':')
              .replaceAll('\'', '"');
        } catch (e) {
          dataString = options.data.toString();
        }
        buffer.write(" -d '$dataString'");
      } else if (options.data is String) {
        buffer.write(" -d '${options.data}'");
      }
    }

    // Add form data for multipart/form-data
    if (options.data is FormData) {
      final formData = options.data as FormData;
      for (var field in formData.fields) {
        buffer.write(" -d '${field.key}=${field.value}'");
      }
      for (var file in formData.files) {
        buffer.write(" -F '${file.key}=@<filepath>'");
      }
    }

    return buffer.toString();
  }

  String _buildPostmanCollection(RequestOptions options) {
    // Build query params
    List<Map<String, dynamic>> queryParams = [];
    if (options.queryParameters.isNotEmpty) {
      options.queryParameters.forEach((key, value) {
        queryParams.add({
          'key': key,
          'value': value.toString(),
          'enabled': true,
        });
      });
    }

    // Build headers
    List<Map<String, dynamic>> headers = [];
    options.headers.forEach((key, value) {
      if (key.toLowerCase() != 'content-type') {
        headers.add({'key': key, 'value': value.toString(), 'type': 'text'});
      }
    });

    // Add Content-Type header
    if (options.data != null && options.method != 'GET') {
      headers.add({
        'key': 'Content-Type',
        'value': 'application/json',
        'type': 'text',
      });
    }

    // Build request body if exists
    Map<String, dynamic> body = {};
    if (options.data != null &&
        options.method != 'GET' &&
        options.data is! FormData) {
      body = {
        'mode': 'raw',
        'raw': options.data.toString().replaceAll('\'', '"'),
      };
    }

    // Build full URL with query params
    String fullUrl = '${options.baseUrl}${options.path}';
    if (queryParams.isNotEmpty) {
      final queryString = queryParams
          .map((p) => '${p['key']}=${p['value']}')
          .join('&');
      fullUrl = '$fullUrl?$queryString';
    }

    // Create Postman collection item (simplified format)
    final collectionItem = {
      'name': '${options.method.toUpperCase()} ${options.path}',
      'request': {
        'method': options.method,
        'header': headers,
        'url': fullUrl,
        if (body.isNotEmpty) 'body': body,
      },
    };

    return const JsonEncoder.withIndent('  ').convert(collectionItem);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _printResponse(response);
    super.onResponse(response, handler);
  }

  void _printResponse(Response response) {
    final buffer = StringBuffer();

    buffer.writeln('\n${"=" * 60}');
    buffer.writeln('✅ CURL RESPONSE');
    buffer.writeln('${"=" * 60}');

    buffer.writeln('\n🔹 Status Code: ${response.statusCode}');
    buffer.writeln('🔹 URL: ${response.requestOptions.uri}');

    if (response.data != null) {
      buffer.writeln('\n📦 Response Data:');
      try {
        buffer.writeln('   ${response.data}');
      } catch (e) {
        buffer.writeln('   ${response.data.toString()}');
      }
    }

    buffer.writeln('\n${"=" * 60}\n');

    print(buffer.toString());
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _printError(err);
    super.onError(err, handler);
  }

  void _printError(DioException err) {
    final buffer = StringBuffer();

    buffer.writeln('\n${"=" * 60}');
    buffer.writeln('❌ CURL ERROR');
    buffer.writeln('${"=" * 60}');

    buffer.writeln('\n🔹 Error Type: ${err.type}');
    buffer.writeln('🔹 URL: ${err.requestOptions.uri}');
    buffer.writeln('🔹 Status Code: ${err.response?.statusCode}');

    if (err.response?.data != null) {
      buffer.writeln('\n📦 Error Data:');
      buffer.writeln('   ${err.response?.data}');
    }

    if (err.message != null) {
      buffer.writeln('\n💬 Message: ${err.message}');
    }

    buffer.writeln('\n${"=" * 60}\n');

    print(buffer.toString());
  }
}
