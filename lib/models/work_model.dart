class WorkModel {
  final String id;
  final String title;
  final String? summary;
  final String? author;
  final String? fandom;
  final List<String>? tags;
  final int? words;
  final int? chapters;
  final String? rating;
  final String? status;

  WorkModel({
    required this.id,
    required this.title,
    this.summary,
    this.author,
    this.fandom,
    this.tags,
    this.words,
    this.chapters,
    this.rating,
    this.status,
  });

  factory WorkModel.fromJson(Map<String, dynamic> json) {
    return WorkModel(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      author: json['author'] as String?,
      fandom: json['fandom'] as String?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : null,
      words: json['words'] as int?,
      chapters: json['chapters'] as int?,
      rating: json['rating'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'author': author,
      'fandom': fandom,
      'tags': tags,
      'words': words,
      'chapters': chapters,
      'rating': rating,
      'status': status,
    };
  }

  @override
  String toString() {
    return 'WorkModel(id: $id, title: $title, author: $author)';
  }
}
