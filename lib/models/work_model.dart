class WorkStats {
  final String? language;
  final String? words;
  final String? chapters;
  final String? comments;
  final String? kudos;
  final String? bookmarks;
  final String? hits;

  WorkStats({
    this.language,
    this.words,
    this.chapters,
    this.comments,
    this.kudos,
    this.bookmarks,
    this.hits,
  });

  factory WorkStats.fromJson(Map<String, dynamic> json) {
    return WorkStats(
      language: json['Language'] as String?,
      words: json['Words'] as String?,
      chapters: json['Chapters'] as String?,
      comments: json['Comments'] as String?,
      kudos: json['Kudos'] as String?,
      bookmarks: json['Bookmarks'] as String?,
      hits: json['Hits'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Language': language,
      'Words': words,
      'Chapters': chapters,
      'Comments': comments,
      'Kudos': kudos,
      'Bookmarks': bookmarks,
      'Hits': hits,
    };
  }
}

class WorkModel {
  final String id;
  final String title;
  final String author;
  final String summary;
  final List<String> tags;
  final WorkStats stats;

  WorkModel({
    required this.id,
    required this.title,
    required this.author,
    required this.summary,
    required this.tags,
    required this.stats,
  });

  factory WorkModel.fromJson(Map<String, dynamic> json) {
    return WorkModel(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      summary: json['summary'] as String,
      tags: List<String>.from(json['tags'] as List),
      stats: WorkStats.fromJson(json['stats'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'summary': summary,
      'tags': tags,
      'stats': stats.toJson(),
    };
  }

  @override
  String toString() {
    return 'WorkModel(id: $id, title: $title, author: $author)';
  }
}
