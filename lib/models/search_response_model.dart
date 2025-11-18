import 'work_model.dart';

class SearchResponse {
  final int totalResults;
  final int page;
  final List<WorkModel> works;

  SearchResponse({
    required this.totalResults,
    required this.page,
    required this.works,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      totalResults: json['total_results'] as int,
      page: json['page'] as int,
      works: (json['works'] as List)
          .map((work) => WorkModel.fromJson(work as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_results': totalResults,
      'page': page,
      'works': works.map((work) => work.toJson()).toList(),
    };
  }

  /// Check if there are more pages available
  bool get hasMorePages {
    if (works.isEmpty) return false;

    // Calculate total items shown so far
    final itemsShown = page * works.length;

    // If total results is greater than items shown, there are more pages
    return totalResults > itemsShown;
  }

  @override
  String toString() {
    return 'SearchResponse(totalResults: $totalResults, page: $page, works: ${works.length})';
  }
}
